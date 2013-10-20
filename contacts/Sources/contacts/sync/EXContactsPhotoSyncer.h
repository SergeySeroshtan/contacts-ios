//
//  EXContactsPhotoSyncer.h
//  contacts
//
//  Created by Sergey Seroshtan on 19.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Block to observe photos synchronization progress.
 */
typedef void(^EXContactsPhotoSyncerProgressObserver)(NSUInteger total, NSUInteger done);

@class EXContactsStorage;

@interface EXContactsPhotoSyncer : NSObject

/// @name Initialization
/**
 * Initializa photo syncer with contacts storage.
 */
- (id)initWithContactsStorage:(EXContactsStorage *)contactsStorage;

/// @name Info
/**
 * @return YES - if photo syncer now synchronize photos, NO - otherwise.
 */
- (BOOL)isSynchronizing;
/**
 * @return YES - if photo syncer was suspended, NO - otherwise.
 */
- (BOOL)isSuspended;
/**
 * @return YES - if photo syncer was stopped, NO - otherwise.
 */
- (BOOL)isStopped;

/// @name Managing
/**
 * Start photos background synchronization.
 */
- (void)start;
/**
 * Stop photos synchronization.
 */
- (void)stop;
/**
 * Reset current synchronization progress and start from the beginning.
 * @param force If YES - all photos, even already synchronized, will be resynchronized.
 */
- (void)resync:(BOOL)force;
/**
 * Suspend photos synchronization.
 */
- (void)suspend;
/**
 * Resume photos synchronization.
 */
- (void)resume;

/// @name Progress observer
/**
 * Add observer for photos synchronization progress.
 */
- (void)addProgressObserver:(EXContactsPhotoSyncerProgressObserver)progressObserver withId:(NSString *)observerId;

/**
 * Remove observer for photos synchronization progress.
 */
- (void)removeProgressObserver:(NSString *)observerId;

/**
 * @return YES if observer with specified id was already registered.
 */
- (BOOL)containsProggressObserver:(NSString *)observerId;

@end
