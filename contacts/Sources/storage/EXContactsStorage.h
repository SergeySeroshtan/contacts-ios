//
//  EXContactsStorage.h
//  contacts
//
//  Created by Sergey Seroshtan on 16.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Completion callback
 */
typedef void(^EXContactsStorageCompletion)(BOOL success, NSError *error);

/**
 * This class manages persistant storages for contacts.
 */
@interface EXContactsStorage : NSObject

/**
 * Contains last error, if some method returns NO.
 */
@property (strong, nonatomic, readonly) NSError *error;

/// @name Access
/**
 * @return YES - if user can interact with address book
 */
- (BOOL)isAccessible;

/**
 * Application should invoke this method to ask user access permissions to address book.
 */
- (void)requestAccessWithCompletion:(EXContactsStorageCompletion)completion;

/**
 * @return Last synchronization date.
 */
 - (NSDate *)lastSyncDate;

/// @name Managing
/**
 * Synchronize all contacts in address book and contacts info storage.
 */
- (BOOL)syncContacts:(NSArray *)contacts;

/**
 * Drop all contacts information.
 */
- (BOOL)drop;

@end
