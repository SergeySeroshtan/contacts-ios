//
//  EXContactsPhotoSyncer.m
//  contacts
//
//  Created by Sergey Seroshtan on 19.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsPhotoSyncer.h"

#import <AFNetworking/AFNetworking.h>

#import "EXContactsStorage.h"

/**
 * Describes photos syncer state
 */
typedef enum {
    EXContactsPhotoSyncerState_Syncing = 1,
    EXContactsPhotoSyncerState_Stopped,
    EXContactsPhotoSyncerState_Suspended
} EXContactsPhotoSyncerState;

#pragma mark - Configuration constatnts
static const NSUInteger kPhotos_MaxConcurrentCount = 3;

#pragma mark - Sync queue state observe constants
static NSString * const kSyncQueueObserveContext = @"EXContactsPhotoSyncer_SyncQueueObserveContext";
static NSString * const kSyncQueueObserveValue_OperationCount = @"operationCount";

@interface EXContactsPhotoSyncer ()

@property (assign, nonatomic) EXContactsPhotoSyncerState state;

@property (strong, nonatomic) EXContactsStorage *contactsStorage;
@property (strong, nonatomic) NSOperationQueue *syncQueue;
@property (assign, nonatomic) NSUInteger totalPhotosInSyncQueueCount;

@property (strong, nonatomic) NSMutableDictionary *progressObservers;

@end

@implementation EXContactsPhotoSyncer

- (id)init
{
    PRECONDITION_TRUE(NO);
}

- (id)initWithContactsStorage:(EXContactsStorage *)contactsStorage
{
    PRECONDITION_ARG_NOT_NIL(contactsStorage);
    if (self = [super init]) {
        self.state = EXContactsPhotoSyncerState_Stopped;
        self.contactsStorage = contactsStorage;
        
        self.syncQueue = [[NSOperationQueue alloc] init];
        self.syncQueue.maxConcurrentOperationCount = kPhotos_MaxConcurrentCount;
        [self.syncQueue addObserver:self forKeyPath:kSyncQueueObserveValue_OperationCount
                options:NSKeyValueObservingOptionNew context:(__bridge void *)kSyncQueueObserveContext];
        
        self.progressObservers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Info
- (BOOL)isSynchronizing
{
    return self.state == EXContactsPhotoSyncerState_Syncing;
}

- (BOOL)isStopped
{
    return self.state == EXContactsPhotoSyncerState_Stopped;
}

- (BOOL)isSuspended
{
    return self.state == EXContactsPhotoSyncerState_Suspended;
}

#pragma mark - Photos managing
- (void)start
{
    if (self.state != EXContactsPhotoSyncerState_Syncing) {
        [self resync:NO];
    }
}

- (void)stop
{
    if (self.state != EXContactsPhotoSyncerState_Stopped) {
        [self.syncQueue cancelAllOperations];
        self.totalPhotosInSyncQueueCount = 0;
        self.state = EXContactsPhotoSyncerState_Stopped;
    }
}

- (void)resync:(BOOL)force
{
    if (force) {
        [self.contactsStorage invalidateAllPhotos];
    }

    [self.syncQueue cancelAllOperations];
    [self.syncQueue setSuspended:YES];

    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"init"]];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];

    NSArray *photosUrl = [self.contactsStorage retreiveUnsyncedPhotosUrl];
    for (NSString * urlString in photosUrl) {
        if (![urlString exist]) {
            continue;
        }

        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation
            setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self syncPhoto:responseObject withUrl:operation.request.URL.absoluteString];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // Ignore
                NSLog(@"Failed HTTP request: %@, due to error %@", operation.request, error);
            }
        ];

        [self.syncQueue addOperation:operation];
    }
    
    self.totalPhotosInSyncQueueCount = self.syncQueue.operationCount;
    self.state = EXContactsPhotoSyncerState_Syncing;
    [self.syncQueue setSuspended:NO];
}

- (void)suspend
{
    if (self.state == EXContactsPhotoSyncerState_Syncing) {
        [self.syncQueue setSuspended:YES];
        self.state = EXContactsPhotoSyncerState_Suspended;
    }
}

- (void)resume
{
    if (self.state == EXContactsPhotoSyncerState_Suspended) {
        [self.syncQueue setSuspended:NO];
        self.state = EXContactsPhotoSyncerState_Syncing;
    }
}

#pragma mark - Progress observer
- (void)addProgressObserver:(EXContactsPhotoSyncerProgressObserver)progressObserver withId:(NSString *)observerId
{
    PRECONDITION_ARG_NOT_NIL(progressObserver);
    PRECONDITION_ARG_NOT_NIL(observerId);
    [self.progressObservers setObject:progressObserver forKey:observerId];
}

- (void)removeProgressObserver:(NSString *)observerId
{
    PRECONDITION_ARG_NOT_NIL(observerId);
    [self.progressObservers removeObjectForKey:observerId];
}

- (BOOL)containsProggressObserver:(NSString *)observerId
{
    PRECONDITION_ARG_NOT_NIL(observerId);
    return [self.progressObservers objectForKey:observerId] != nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
        context:(void *)context
{
    if (context == (__bridge void *)kSyncQueueObserveContext &&
            [keyPath isEqualToString:kSyncQueueObserveValue_OperationCount]) {
        if (self.isSynchronizing) {
            NSNumber *operationCount = [change objectForKey:NSKeyValueChangeNewKey];
            NSUInteger done = self.totalPhotosInSyncQueueCount - operationCount.unsignedIntegerValue;
            [self fireProgressObserverWithTotal:self.totalPhotosInSyncQueueCount done:done];
            if (done == self.totalPhotosInSyncQueueCount) {
                [self stop];
            }
        }
    }
}

- (void)fireProgressObserverWithTotal:(NSUInteger)total done:(NSUInteger)done
{
    for (NSString *observerId in self.progressObservers) {
        EXContactsPhotoSyncerProgressObserver observer = [self.progressObservers objectForKey:observerId];
        observer(total, done);
    }
}

#pragma mark - Private
/**
 * Invokes photo synchronization in main thread.
 */
- (void)syncPhoto:(NSData *)photo withUrl:(NSString *)url
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.contactsStorage syncPhoto:photo withUrl:url];
    });
}

@end
