//
//  EXContactsInfoStorage.h
//  contacts
//
//  Created by Sergey Seroshtan on 16.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EXContact;

/**
 * This class provides access to EXContactInfo objects permanent storage.
 */
@interface EXContactsInfoStorage : NSObject

/// @name Info properties
/**
 * Contains last error, if some method returns NO.
 */
@property (strong, nonatomic, readonly) NSError *error;

/// @name Initialization
- (id)init;

/// @name Access permissions
/**
 * @return YES if initialization was successfull and all methods from 'Managing' section can be used, NO otherwise.
 */
- (BOOL)isAccessible;

/// @name Info
/**
 * @return all persons identifiers (array NSNumber class objects).
 */
- (NSArray *)allPersonIds;

/**
 * @return persons identifiers for specified contacts (array NSNumber class objects).
 */
- (NSArray *)personIdsForContacts:(NSArray *)contacts;

/**
 * Read contact information for specifed persons (array of NSNumber),
 *     to specified contacts (array of EXContact class object).
 */
- (BOOL)readContactInfoForPersonIds:(NSArray *)personIds toContacts:(NSArray *)contacts;

/// @name Managing
/**
 * Add contact information for specified persons.
 * @param personIds Array of persons identifiers (NSNumber).
 * @param contacts Array of contacts (EXContact).
 */
- (BOOL)addContactInfoForPersonIds:(NSArray *)personIds contacts:(NSArray *)contacts;

/**
 * Update contact information for specified contacts.
 * @param contacts Contacts to be updated .
 * @return Updated contacts (array of EXContact). Note that returned array may be smaller,
 *     because not all specified contacts should be updated.
 */
- (NSArray *)updateContactInfoForContacts:(NSArray *)contacts;

/**
 * Remove contact information for specifed persons.
 */
- (BOOL)removeContactInfoForPersonIds:(NSArray *)personIds;

/**
 * Remove all contacts information for person ids if it not listed in specified parameter.
 * @param personIds Array of person identifiers (NSUInteger class objects).
 */
- (BOOL)leaveContactInfoOnlyForPersonIds:(NSArray *)personIds;

/**
 * Drop storage with all related data.
 */
- (BOOL)drop;

@end
