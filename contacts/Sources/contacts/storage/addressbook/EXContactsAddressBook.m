//
//  EXContactsAddressBook.m
//  contacts
//
//  Created by Sergey Seroshtan on 14.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsAddressBook.h"

#import <AddressBook/AddressBook.h>

#import "EXABPersonAttribute.h"

#import "EXAppSettings.h"

#import "EXContact.h"
#import "EXContactInfo.h"
#import "EXContactsInfoStorage.h"

#pragma mark - Address Book constants
static NSString * const kContactsGroupName = @"coworkers";

@interface EXContactsAddressBook ()

@property (strong, nonatomic, readwrite) NSError *error;
@property (assign, nonatomic) ABAddressBookRef addressBook;
@property (assign, nonatomic) ABRecordRef coworkersGroup;

@end

@implementation EXContactsAddressBook

#pragma mark - Initialize
- (id)init
{
    if (self = [super init]) {
        [self tryAddressBookLasyInit];
    }
    return self;
}

- (void)dealloc
{
    CF_SAFE_RELEASE(self.addressBook);
    CF_SAFE_RELEASE(self.coworkersGroup);
}

#pragma mark - Access permissions
- (BOOL)isAccessible
{
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (void)requestAccessWithCompletion:(EXContactsAddressBookCompletion)completion
{
    PRECONDITION_ARG_NOT_NIL(completion);

    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        completion(granted, CFBridgingRelease(error));
    });
}

#pragma mark - Access
- (NSArray *)allPersonIds
{
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return nil;
    }

    NSArray *persons = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(self.coworkersGroup));
    if (persons == nil) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:persons.count];
    for (size_t pos = 0; pos < persons.count; ++pos) {
        ABRecordRef person = (__bridge ABRecordRef)persons[pos];
        NSNumber *personId = [NSNumber numberWithInteger:ABRecordGetRecordID(person)];
        [result addObject:personId];
    }

    return result;
}

- (NSArray *)allContacts
{
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return nil;
    }

    NSArray *persons = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(self.coworkersGroup));
    if (persons == nil) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:persons.count];
    for (size_t pos = 0; pos < persons.count; ++pos) {
        ABRecordRef person = (__bridge ABRecordRef)persons[pos];
        EXContact *contact = [self createContactFromABPerson:person];
        [result addObject:contact];
    }

    return result;
}

- (NSArray *)contactsForPersonIds:(NSArray *)personIds
{
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:personIds.count];
    for (NSNumber *personId in personIds) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(self.addressBook, personId.intValue);
        if (person == NULL) {
            break;
        }
        EXContact *contact = [self createContactFromABPerson:person];
        [result addObject:contact];
    }

    return result;
}

#pragma mark - Managing
- (NSArray *)addPersonsForContacts:(NSArray *)contacts
{
    PRECONDITION_ARG_NOT_NIL(contacts);
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    CFErrorRef error = NULL;
    ABRecordRef person = NULL;
    for (EXContact *contact in contacts) {
        person = [self createABPersonFromContact:contact];
        BREAK_IF_FALSE(ABAddressBookAddRecord(self.addressBook, person, &error));
        BREAK_IF_FALSE(ABGroupAddMember(self.coworkersGroup, person, &error));
        BREAK_IF_FALSE(ABAddressBookSave(self.addressBook, &error));
        [result addObject:[NSNumber numberWithInteger:ABRecordGetRecordID(person)]];
        CF_SAFE_RELEASE(person);
    }
    CF_SAFE_RELEASE(person);
    self.error = error ? CFBridgingRelease(error) : nil;
    return result;
}

- (BOOL)updatePersonWithIds:(NSArray *)personIds contacts:(NSArray *)contacts
{
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_ARG_NOT_NIL(contacts)
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return NO;
    }

    CFErrorRef error = NULL;
    size_t personsForUpdateCount = MIN(personIds.count, contacts.count);
    for (size_t pos = 0; pos < personsForUpdateCount; ++pos) {
        EXContact *contact = contacts[pos];

        NSNumber *personId = personIds[pos];
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(self.addressBook, personId.intValue);
        if (person == NULL) {
            continue;
        }

        EXABPersonAttribute *personAttribute = [[EXABPersonAttribute alloc] initWithABPerson:person];
        personAttribute.firstName = contact.firstName;
        personAttribute.lastName = contact.lastName;
        personAttribute.mail = contact.mail;
        personAttribute.phone = contact.phone;
        personAttribute.skype = contact.skype;
        personAttribute.location = contact.location;
        personAttribute.position = contact.position;
        BREAK_IF_FALSE(ABAddressBookSave(self.addressBook, &error));
    }

    if (error) {
        self.error = CFBridgingRelease(error);
        return NO;
    } else {
        self.error = nil;
        return YES;
    }
}

- (BOOL)removePersonWithIds:(NSArray *)personIds
{
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return NO;
    }

    CFErrorRef error = NULL;
    for (NSNumber *personId in personIds) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(self.addressBook, [personId intValue]);
        if (person == NULL) {
            continue;
        }
        BREAK_IF_FALSE(ABAddressBookRemoveRecord(self.addressBook, person, &error));
        BREAK_IF_FALSE(ABAddressBookSave(self.addressBook, &error));
    }

    if (error) {
        self.error = CFBridgingRelease(error);
        return NO;
    } else {
        self.error = nil;
        return YES;
    }
}

- (BOOL)leavePersonWithIds:(NSArray *)personIds
{
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return NO;
    }

    NSSet *personIdsSet = [NSSet setWithArray:personIds];

    CFErrorRef error = NULL;
    NSArray *persons = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(self.coworkersGroup));
    for (size_t pos = 0; pos < persons.count; ++pos) {
        ABRecordRef person = (__bridge ABRecordRef)persons[pos];
        NSNumber *personId = [NSNumber numberWithInt:ABRecordGetRecordID(person)];
        if ([personIdsSet member:personId] == nil) {
            BREAK_IF_FALSE(ABAddressBookRemoveRecord(self.addressBook, person, NULL));
            BREAK_IF_FALSE(ABAddressBookSave(self.addressBook, &error));
        }
    }

    if (error) {
        self.error = CFBridgingRelease(error);
        return NO;
    } else {
        self.error = nil;
        return YES;
    }
}

- (BOOL)drop
{
    PRECONDITION_TRUE(self.isAccessible);

    if ([self tryAddressBookLasyInit] == NO) {
        return NO;
    }
    NSArray *persons = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(self.coworkersGroup));
    for (size_t pos = 0; pos < persons.count; ++pos) {
        ABRecordRef person = (__bridge ABRecordRef)persons[pos];
        ABAddressBookRemoveRecord(self.addressBook, person, NULL);
    }
    ABAddressBookRemoveRecord(self.addressBook, self.coworkersGroup, NULL);
    CF_SAFE_RELEASE(self.coworkersGroup);
    ABAddressBookSave(self.addressBook, NULL);
    return YES;
}

#pragma mark - Photos managing
- (void)setPhoto:(NSData *)photo forPerson:(NSUInteger)personId
{
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(self.addressBook , personId);
    if (person == NULL) {
        return;
    }
    
    EXABPersonAttribute *personAttribute = [[EXABPersonAttribute alloc] initWithABPerson:person];
    personAttribute.photo = photo;
    
    ABAddressBookSave(self.addressBook, NULL);
}

- (void)removePhotoForPerson:(NSUInteger)personId
{
    [self setPhoto:nil forPerson:personId];
}

#pragma mark - Private
#pragma mark - AddressBook
- (BOOL)tryAddressBookLasyInit
{
    if (self.addressBook && self.coworkersGroup) {
        return YES;
    }
    if (self.addressBook == NULL && [self isAccessible]) {
        // Get access to Address Book
        CFErrorRef error = NULL;
        self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (error) {
            self.error = CFBridgingRelease(error);
        }
    }
    if (self.addressBook != NULL && self.coworkersGroup == NULL) {
        // Get group if exists
        NSArray *groups = CFBridgingRelease(ABAddressBookCopyArrayOfAllGroups(self.addressBook));
        for (size_t pos = 0; pos < groups.count; ++pos) {
            ABRecordRef group = (__bridge ABRecordRef)groups[pos];
            NSString *groupName = CFBridgingRelease(ABRecordCopyValue(group, kABGroupNameProperty));
            if ([groupName isEqualToString:kContactsGroupName]) {
                self.coworkersGroup = CFRetain(group);
                break;
            }
        }

        // Or create it otherwise
        if (self.coworkersGroup == NULL) {
            self.coworkersGroup = ABGroupCreate();
            ABRecordSetValue(self.coworkersGroup, kABGroupNameProperty, (__bridge CFStringRef)kContactsGroupName, NULL);
            ABAddressBookAddRecord(self.addressBook, self.coworkersGroup, NULL);
            ABAddressBookSave(self.addressBook, NULL);
        }
    }
    return self.addressBook != NULL && self.coworkersGroup != NULL;
}

- (ABRecordRef)createABPersonFromContact:(EXContact *)contact
{
    PRECONDITION_ARG_NOT_NIL(contact);
    
    ABRecordRef person = ABPersonCreate();

    EXABPersonAttribute *personAttribute = [[EXABPersonAttribute alloc] initWithABPerson:person];
    personAttribute.firstName = contact.firstName;
    personAttribute.lastName = contact.lastName;
    personAttribute.mail = contact.mail;
    personAttribute.phone = contact.phone;
    personAttribute.skype = contact.skype;
    personAttribute.location = contact.location;
    personAttribute.position = contact.position;

    return person;
}

- (EXContact *)createContactFromABPerson:(ABRecordRef)person
{
    PRECONDITION_ARG_NOT_NIL(person);

    EXContact *contact = [[EXContact alloc] init];

    EXABPersonAttribute *personAttribute = [[EXABPersonAttribute alloc] initWithABPerson:person];
    contact.firstName = personAttribute.firstName;
    contact.lastName = personAttribute.lastName;
    contact.mail = personAttribute.mail;
    contact.phone = personAttribute.phone;
    contact.skype = personAttribute.skype;
    contact.location = personAttribute.location;
    contact.position = personAttribute.position;
    
    return contact;
}

@end
