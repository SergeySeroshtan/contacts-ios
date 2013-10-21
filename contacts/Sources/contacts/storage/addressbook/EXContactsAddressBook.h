//
//  EXContactsAddressBook.h
//  contacts
//
//  Created by Sergey Seroshtan on 14.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EXContact;

typedef void(^EXContactsAddressBookCompletion)(BOOL success, NSError *error);

/**
 * This class manages contacts in iOS AddressBook.
 * Note, all methods SHOULD be invoked in the main thread.
 */
@interface EXContactsAddressBook : NSObject

/// @name Info properties
/**
 * Contains last error, if some method returns NO.
 */
@property (strong, nonatomic, readonly) NSError *error;

/// @name Access permissions
/**
 * @return YES - if user can interact with address book
 */
- (BOOL)isAccessible;

/**
 * Application should invoke this method to ask user access permissions to address book.
 */
- (void)requestAccessWithCompletion:(EXContactsAddressBookCompletion)completion;

/// @name Access
/**
 *
 * @return identifiers of all persons.
 */
- (NSArray *)allPersonIds;

/**
 * @return array of EXContact class objects.
 */
- (NSArray *)allContacts;

/**
 * @return array of EXContact class objects.
 */
- (NSArray *)contactsForPersonIds:(NSArray *)personIds;

/// @name Managing
/**
 * Add contacts to address book.
 * @param contacts array of EXContact class objects
 * @return array of added persons identifiers (NSNumber)
 */
- (NSArray *)addPersonsForContacts:(NSArray *)contacts;

/**
 * Update contacts in address book.
 * @param contacts array of EXContact class objects
 */
- (BOOL)updatePersonWithIds:(NSArray *)personIds contacts:(NSArray *)contacts;

/**
 * Remove contacts from address book.
 * @param contacts array of EXContact class objects
 */
- (BOOL)removePersonWithIds:(NSArray *)personIds;

/**
 * Remove all persons if it not listed in specified ids.
 * @param personIds Array of person identifiers (NSUInteger class objects).
 */
- (BOOL)leavePersonWithIds:(NSArray *)personIds;

/**
 * Remove all related persons from address book.
 */
- (BOOL)drop;

/// @name Photos managing
/**
 * Set photo for specifed person.
 */
- (void)setPhoto:(NSData *)photo forPerson:(NSUInteger)personId;

/**
 * Remove photo for specifed person.
 */
- (void)removePhotoForPerson:(NSUInteger)personId;


@end
