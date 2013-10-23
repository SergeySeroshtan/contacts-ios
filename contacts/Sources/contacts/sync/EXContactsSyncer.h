//
//  EXContactsSyncer.h
//  contacts
//
//  Created by Sergey Seroshtan on 20.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EXContact;
@protocol EXContactSyncObserver;

/**
 * Completion block type.
 */
typedef void(^EXContactsSyncerCompletion)(BOOL success, NSError *error);

/**
 * This class provides core functionality for contacts synchronization.
 */
@interface EXContactsSyncer : NSObject

/// @name Singleton
+ (instancetype)sharedInstance;

/// @name Configuration
// Enable or disable photos loading / synchronization.
@property (assign, nonatomic) BOOL loadPhotos;
// Enable or disable mobile netwotk usage.
@property (assign, nonatomic) BOOL useMobileNetworks;
// Enable or disable local notifications about synchronization completion.
@property (assign, nonatomic) BOOL localNotificationEnabled;
// Define contacts group name.
@property (strong, nonatomic) NSString *groupName;
// Define contacts and photos synchronization period in days.
@property (assign, nonatomic) NSUInteger syncPeriod;

/// @name Accessibility
/**
 * @return YES if syncer state is not equal to EXContactsSyncerState_NotAccessible, NO - otherwise.
 */
- (BOOL)isAccessible;

/// @name Address Book
/**
 * @return YES if Address Book access permitted, NO - otherwise.
 */
- (BOOL)isAddressBookAccessPermitted;
/**
 * Application should invoke this method to ask user access permissions to address book.
 */
- (void)requestAddressBookAccessPermissions:(EXContactsSyncerCompletion)completion;

/// @name Authentication
/**
 * Create account for specified user.
 */
- (void)createAccount:(NSString *)username password:(NSString *)password
        completion:(EXContactsSyncerCompletion)completion;
/**
 * Remove user authentication info.
 */
- (void)removeAccount;
/**
 * @return YES if user is signed in, NO - otherwise.
 */
- (BOOL)isUserSignedIn;
/**
 * @return user name if user is signed in, nil - otherwise.
 */
- (EXContact *)signedUserContact;

/// @name Sync managing
- (void)syncNow;
- (void)resyncPhotos;
- (void)awake;
- (void)sleep;

/// @name Sync state
- (BOOL)isSyncContacts;
- (BOOL)isSyncPhotos;

/// @name Sync observing
- (NSDate *)lastSyncDate;
- (void)addSyncObserver:(id<EXContactSyncObserver>)syncObserver;
- (void)removeSyncObserver:(id<EXContactSyncObserver>)syncObserver;

@end

@protocol EXContactSyncObserver <NSObject>
@optional

/// @name Contacts sync
- (void)contactsSyncerDidStartContactsSync:(EXContactsSyncer *)contactsSyncer;
- (void)contactsSyncerDidFinishContactsSync:(EXContactsSyncer *)contactsSyncer;
- (void)contactsSyncerDidFailContactsSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error;

/// @name Photos sync
- (void)contactsSyncer:(EXContactsSyncer *)contactsSyncer didStartPhotosSync:(NSUInteger)photosCount;
- (void)contactsSyncer:(EXContactsSyncer *)contactsSyncer didSyncPhotos:(NSUInteger)syncedPhotosCount
        ofTotal:(NSUInteger)totalPhotosCount;
- (void)contactsSyncerDidFinishPhotosSync:(EXContactsSyncer *)contactsSyncer;
- (void)contactsSyncerDidFailPhotosSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error;

@end
