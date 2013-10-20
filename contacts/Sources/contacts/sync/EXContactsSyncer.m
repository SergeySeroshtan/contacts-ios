//
//  EXContactsSyncer.m
//  contacts
//
//  Created by Sergey Seroshtan on 20.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsSyncer.h"

#import <AFNetworking/AFNetworking.h>

#import "EXAppSettings.h"
#import "EXContactsService.h"
#import "EXContactsStorage.h"

/**
 * Syncer state type.
 */
typedef enum {
    EXContactsSyncerState_Stopped = 0,
    EXContactsSyncerState_Started,
    EXContactsSyncerState_Suspended,
    EXContactsSyncerState_Resumed,
    EXContactsSyncerState_NotAccessible
} EXContactsSyncerState;

#pragma mark - User defaults constants

@interface EXContactsSyncer ()

@property (assign, nonatomic) EXContactsSyncerState internalState;
@property (strong, nonatomic) EXContactsStorage *contactsStorage;
@property (strong, nonatomic) EXContactsService *contactsService;
@property (strong, nonatomic) NSMutableSet *syncObservers;
@property (strong, nonatomic) AFHTTPClient *httpClient;
@property (strong, nonatomic) NSOperationQueue *photosSyncQueue;

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
        self.internalState = EXContactsSyncerState_Stopped;
        self.contactsService = [[EXContactsService alloc] init];
        self.contactsStorage = [[EXContactsStorage alloc] init];
        self.syncObservers = [[NSMutableSet alloc] init];
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kContactsServiceUrl]];
        
        [self addObserver:self forKeyPath:@"internalState" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
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
            [self start];
        }
        completion(success, error);
    }];
}

- (void)removeAccount
{
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
- (void)start
{
    if (!self.isAccessible || self.internalState == EXContactsSyncerState_Started ||
            self.internalState == EXContactsSyncerState_Resumed) {
        return;
    }
    self.internalState = EXContactsSyncerState_Started;
    [self resume];
}

- (void)stop
{
    self.internalState = EXContactsSyncerState_Stopped;
}

- (void)suspend
{

}

- (void)resume
{
    if (!self.isAccessible || self.internalState == EXContactsSyncerState_Resumed) {
        return;
    }
    
    // Sync contacts if needed
    [self fireWillStartContactsSync];
    [self fireDidStartContactsSync];
    [self.contactsService coworkers:^(BOOL success, id data, NSError *error) {
        self.internalState = EXContactsSyncerState_Stopped;
        if (success) {
            [self.contactsStorage syncContacts:data];
            [self fireDidFinishContactsSync];
        } else {
            [self fireDidFailContactsSyncWithError:error];
        }
    }];
    
    self.internalState = EXContactsSyncerState_Resumed;
}

#pragma mark - Sync state
- (BOOL)isAccessible
{
    [self updateInternalState];
    return self.internalState != EXContactsSyncerState_NotAccessible;
}

/// @name Sync observing
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
        context:(void *)context
{
    NSNumber *newState = [change objectForKey:NSKeyValueChangeNewKey];
    [self logInternalStateChanged:newState.intValue];
}

#pragma mark - Private
#pragma mark - Sync state
- (void)updateInternalState
{
    BOOL accessible = YES;
    if (!self.contactsStorage.isAccessible) {
        accessible = NO;
    } else {
//        switch (self.networkStatus) {
//            case ReachableViaWiFi:
//                break;
//            case ReachableViaWWAN:
//                accessible = self.mobileNetworksEnabled;
//                break;
//            case NotReachable:
//            default:
//                accessible = NO;
//                break;
//        }
    }
    if (!accessible) {
        self.internalState = EXContactsSyncerState_NotAccessible;
    }
}

#pragma mark - Sync observer notification
- (void)fireWillStartContactsSync
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerWillStartContactsSync:)]) {
                continue;
            }
            [observer contactsSyncerWillStartContactsSync:self];
        }
    });
}

- (void)fireDidStartContactsSync
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidStartContactsSync:)]) {
                continue;
            }
            [observer contactsSyncerDidStartContactsSync:self];
        }
    });
}

- (void)fireDidFinishContactsSync
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFinishContactsSync:)]) {
                continue;
            }
            [observer contactsSyncerDidFinishContactsSync:self];
        }
    });
}

- (void)fireDidFailContactsSyncWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFailContactsSync:withError:)]) {
                continue;
            }
            [observer contactsSyncerDidFailContactsSync:self withError:error];
        }
    });
}

- (void)fireWillStartPhotosSync:(NSUInteger)photosCount;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncer:willStartPhotosSync:)]) {
                continue;
            }
            [observer contactsSyncer:self willStartPhotosSync:photosCount];
        }
    });
}

- (void)fireDidStartPhotosSync:(NSUInteger)photosCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncer:didStartPhotosSync:)]) {
                continue;
            }
            [observer contactsSyncer:self didStartPhotosSync:photosCount];
        }
    });
}

- (void)fireDidSyncPhotos:(NSUInteger)syncedPhotosCount ofTotal:(NSUInteger)totalPhotosCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncer:didSyncPhotos:ofTotal:)]) {
                continue;
            }
            [observer contactsSyncer:self didSyncPhotos:syncedPhotosCount ofTotal:totalPhotosCount];
        }
    });
}

- (void)fireDidFinishPhotosSync:(EXContactsSyncer *)contactsSyncer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFinishPhotosSync:)]) {
                continue;
            }
            [observer contactsSyncerDidFinishPhotosSync:self];
        }
    });
}

- (void)fireDidFailPhotosSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<EXContactSyncObserver> observer in self.syncObservers) {
            if (![observer respondsToSelector:@selector(contactsSyncerDidFailPhotosSync:withError:)]) {
                continue;
            }
            [observer contactsSyncerDidFailPhotosSync:self withError:error];
        }
    });
}

#pragma mark - State change log.
- (void)logInternalStateChanged:(EXContactsSyncerState)newState
{
    NSLog(@"Contacts syncer: new internal state %d", newState);
}

@end
