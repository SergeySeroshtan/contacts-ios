//
//  EXContactsSyncer.m
//  contacts
//
//  Created by Sergey Seroshtan on 20.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsSyncer.h"

#import <AFNetworking/AFNetworking.h>

#import "EXContactsService.h"
#import "EXContactsStorage.h"

#pragma mark - Configuration constatnts
static const NSUInteger kPhotos_MaxConcurrentCount = 3;

#pragma mark - Sync queue state observe constants
static NSString * const kPhotosSyncQueueObserveContext = @"PhotosSyncQueueObserveContext";
static NSString * const kPhotosSyncQueueObserveValue_OperationCount = @"operationCount";

@interface EXContactsSyncer ()

@property (assign) BOOL syncContacts;
@property (assign) BOOL syncPhotos;

@property (strong, nonatomic) EXContactsStorage *contactsStorage;
@property (strong, nonatomic) EXContactsService *contactsService;
@property (strong, nonatomic) NSMutableSet *syncObservers;
@property (strong, nonatomic) AFHTTPClient *httpClient;
@property (strong, nonatomic) NSOperationQueue *photosSyncQueue;
@property (strong, nonatomic) NSOperationQueue *mainQueue;

/// @name Clue for improper use (produces compile time error).
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));

@end

@implementation EXContactsSyncer

#pragma mark - Singleton

+ (instancetype)sharedInstance
{
    static EXContactsSyncer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EXContactsSyncer alloc] initPrivate];
    });
    return instance;
}

- (instancetype)initPrivate
{
    if (self = [super init]) {
        self.syncContacts = NO;
        self.syncPhotos = NO;
        self.contactsService = [[EXContactsService alloc] init];
        self.contactsStorage = [[EXContactsStorage alloc] init];
        self.syncObservers = [[NSMutableSet alloc] init];
        
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kContactsServiceUrl]];
        [self.httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
        
        self.photosSyncQueue = [[NSOperationQueue alloc] init];
        self.photosSyncQueue.maxConcurrentOperationCount = kPhotos_MaxConcurrentCount;

        self.mainQueue = [NSOperationQueue mainQueue];
    }
    return self;
}

#pragma mark - Accessors
- (void)setUseMobileNetworks:(BOOL)mobileNetworksEnabled
{
    _useMobileNetworks = mobileNetworksEnabled;
    self.contactsService.useMobileNetworks = mobileNetworksEnabled;
}

#pragma mark - Accessiblity
- (BOOL)isAccessible
{
    return self.contactsService.isUserSignedIn && self.contactsStorage.isAccessible;
}

#pragma mark - Address Book

- (BOOL)isAddressBookAccessPermitted
{
    return self.contactsStorage.isAccessible;
}

- (void)requestAddressBookAccessPermissions:(EXContactsSyncerCompletion)completion
{
    PRECONDITION_ARG_NOT_NIL(completion);
    [self.contactsStorage requestAccessWithCompletion:^(BOOL success, NSError *error) {
        completion(success, error);
    }];
}

#pragma mark - Authentication
- (void)createAccount:(NSString *)username password:(NSString *)password
        completion:(EXContactsSyncerCompletion)completion
{
    PRECONDITION_ARG_NOT_NIL(username);
    PRECONDITION_ARG_NOT_NIL(password);
    PRECONDITION_ARG_NOT_NIL(completion);
    [self.contactsService signInUser:username password:password completion:^(BOOL success, id data, NSError *error) {
        if (success) {
            [self awake];
        }
        completion(success, error);
    }];
}

- (void)removeAccount
{
    [self.syncObservers removeAllObjects];
    [self.contactsStorage drop];
    [self.contactsService signOut];
}

- (BOOL)isUserSignedIn
{
    return self.contactsService.isUserSignedIn;
}

- (EXContact *)signedUserContact
{
    return self.contactsService.signedUserContact;
}

#pragma mark - Sync managing
- (void)syncNow
{
    if (self.syncContacts) {
        return;
    }
    [self syncAll];
}

- (void)resyncPhotos
{
    if (self.syncPhotos) {
        [self stopPhotosSync];
    }
    [self.contactsStorage invalidateAllPhotos];
    [self startSyncPhotos];
}

- (void)awake
{
    if ([self needSyncAll]) {
        [self syncAll];
    } else if (self.syncPhotos) {
        [self resumeSyncPhotos];
    } else {
        [self startSyncPhotos];
    }
}

- (void)sleep
{
    if (self.syncPhotos) {
        [self suspendSyncPhotos];
    }
}

- (BOOL)needSyncAll
{
    if ([self lastSyncDate] == nil) {
        return YES;
    }

    NSTimeInterval daysFromLastSync = ABS([[self lastSyncDate] timeIntervalSinceNow]) / 60 / 60 / 24;
    if (daysFromLastSync > self.syncPeriod) {
        return YES;
    }

    return NO;
}

- (void)syncAll
{
    if (self.syncPhotos) {
        [self stopPhotosSync];
    }
    self.syncContacts = YES;
    [self fireDidStartContactsSync];
    [self.contactsService coworkers:^(BOOL success, id data, NSError *error) {
        if (success) {
            [self.mainQueue addOperationWithBlock:^{
                [self.contactsStorage syncContacts:data];
                [self fireDidFinishContactsSync];
                [self startSyncPhotos];
            }];
        } else {
            [self fireDidFailContactsSyncWithError:error];
        }
        self.syncContacts = NO;
    }];
}

- (void)startSyncPhotos
{
    if (self.syncPhotos) {
        return;
    } else if (!self.loadPhotos) {
        return;
    }
    
    NSArray *photosUrl = [self.contactsStorage retreiveUnsyncedPhotosUrl];
    const NSUInteger totalSyncPhotosCount = photosUrl.count;
    if (totalSyncPhotosCount == 0) {
        return;
    }

    NSOperation *photosFinishSyncOperation = [NSBlockOperation blockOperationWithBlock:^{
        self.syncPhotos = NO;
        [self fireDidFinishPhotosSync];
    }];

    [self.photosSyncQueue setSuspended:YES];
    for (NSString * urlString in photosUrl) {
        if (![urlString exist]) {
            continue;
        }

        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation
            setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self processLoadedPhoto:responseObject fromUrl:operation.request.URL.absoluteString
                        ofTotalCount:totalSyncPhotosCount];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // Ignore error
            }
        ];
        [self.photosSyncQueue addOperation:operation];
        [photosFinishSyncOperation addDependency:operation];
    }
    [self.photosSyncQueue addOperation:photosFinishSyncOperation];
    self.syncPhotos = YES;
    [self fireDidStartPhotosSync:totalSyncPhotosCount];
    [self.photosSyncQueue setSuspended:NO];
}

- (void)stopPhotosSync
{
    if (!self.syncPhotos) {
        return;
    }
    [self.photosSyncQueue cancelAllOperations];
    self.syncPhotos = NO;
    [self fireDidFinishPhotosSync];
}

- (void)resumeSyncPhotos
{
    if (!self.syncPhotos) {
        return;
    } else if (!self.loadPhotos) {
        [self stopPhotosSync];
        return;
    }
    [self.photosSyncQueue setSuspended:NO];
}

- (void)suspendSyncPhotos
{
    if (!self.syncPhotos) {
        return;
    }
    [self.photosSyncQueue setSuspended:YES];
}

- (void)processLoadedPhoto:(NSData *)photo fromUrl:(NSString *)url ofTotalCount:(NSUInteger)totalSyncPhotoCount
{
    PRECONDITION_ARG_NOT_NIL(photo);
    PRECONDITION_ARG_NOT_NIL(url);
    [self.mainQueue addOperationWithBlock:^{
        [self.contactsStorage syncPhoto:photo withUrl:url];
        NSUInteger syncedPhotosCount = totalSyncPhotoCount - self.photosSyncQueue.operationCount;
        [self fireDidSyncPhotos:syncedPhotosCount ofTotal:totalSyncPhotoCount];
    }];
}

#pragma mark - Sync state
- (BOOL)isSyncContacts
{
    return self.syncContacts;
}

- (BOOL)isSyncPhotos
{
    return self.syncPhotos;
}

#pragma mark - Sync observing
- (NSDate *)lastSyncDate
{
    return self.contactsStorage.lastSyncDate;
}

- (void)addSyncObserver:(id<EXContactSyncObserver>)syncObserver
{
    PRECONDITION_ARG_NOT_NIL(syncObserver);
    [self.syncObservers addObject:syncObserver];
}


- (void)removeSyncObserver:(id<EXContactSyncObserver>)syncObserver
{
    PRECONDITION_ARG_NOT_NIL(syncObserver);
    [self.syncObservers removeObject:syncObserver];
}

#pragma mark - Private
#pragma mark - Sync observer notification
- (void)fireDidStartContactsSync
{
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidStartContactsSync:)]) {
                continue;
            }
            [observer contactsSyncerDidStartContactsSync:self];
        }
    }];
}

- (void)fireDidFinishContactsSync
{
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFinishContactsSync:)]) {
                continue;
            }
            [observer contactsSyncerDidFinishContactsSync:self];
        }
    }];
}

- (void)fireDidFailContactsSyncWithError:(NSError *)error
{
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFailContactsSync:withError:)]) {
                continue;
            }
            [observer contactsSyncerDidFailContactsSync:self withError:error];
        }
    }];
}

- (void)fireDidStartPhotosSync:(NSUInteger)photosCount
{
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncer:didStartPhotosSync:)]) {
                continue;
            }
            [observer contactsSyncer:self didStartPhotosSync:photosCount];
        }
    }];
}

- (void)fireDidSyncPhotos:(NSUInteger)syncedPhotosCount ofTotal:(NSUInteger)totalPhotosCount
{
    // TODO: Replace next line with the best solution,
    //     which prevents firing this event after 'fireDidStartPhotosSync' event.
    if (!self.syncPhotos) { return; }
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncer:didSyncPhotos:ofTotal:)]) {
                continue;
            }
            [observer contactsSyncer:self didSyncPhotos:syncedPhotosCount ofTotal:totalPhotosCount];
        }
    }];
}

- (void)fireDidFinishPhotosSync
{
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFinishPhotosSync:)]) {
                continue;
            }
            [observer contactsSyncerDidFinishPhotosSync:self];
        }
    }];
}

- (void)fireDidFailPhotosSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error
{
    [self.mainQueue addOperationWithBlock:^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFailPhotosSync:withError:)]) {
                continue;
            }
            [observer contactsSyncerDidFailPhotosSync:self withError:error];
        }
    }];
}

@end
