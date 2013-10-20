//
//  EXContactsStorage.m
//  contacts
//
//  Created by Sergey Seroshtan on 16.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsStorage.h"

#import "EXAppSettings.h"

#import "EXContact.h"

#import "EXContactsInfoStorage.h"
#import "EXContactsAddressBook.h"

@interface EXContactsStorage ()

@property (strong, nonatomic, readwrite) NSError *error;

@property (strong, nonatomic) EXContactsInfoStorage *infoStorage;
@property (strong, nonatomic) EXContactsAddressBook *addressBook;

@end

@implementation EXContactsStorage

#pragma mark - Initialization
- (id)init
{
    if (self = [super init]) {
        self.infoStorage = [[EXContactsInfoStorage alloc] init];
        self.addressBook = [[EXContactsAddressBook alloc] init];
    }
    return self;
}

#pragma mark - Accessing
- (BOOL)isAccessible
{
    return self.addressBook.isAccessible && self.infoStorage.isAccessible;
}

- (void)requestAccessWithCompletion:(EXContactsStorageCompletion)completion
{
    [self.addressBook
        requestAccessWithCompletion:^(BOOL success, NSError *error) {
            completion(success, error);
        }
    ];
}

- (NSDate *)lastSyncDate
{
    return [EXAppSettings lastSyncDate];
}

/// @name Managing
- (BOOL)syncContacts:(NSArray *)contacts
{
    // Initiate force update if needed
    BOOL needForceUpdate =
            ![[EXAppSettings contactsStorgaeVersion] isEqualToString:[self currentContactStorageVersion]];
    if (needForceUpdate) {
        [self.addressBook drop];
        [self.infoStorage drop];
    }

    NSArray *storedContacts = [self getStoredContacts];

    // 1. Add new contacts.
    NSArray *contactsToAdd = [contacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:
            @"NOT (uid IN %@)", [storedContacts valueForKeyPath:@"@distinctUnionOfObjects.uid"]]];
    NSArray *personIdsToAdd = [self.addressBook addPersonsForContacts:contactsToAdd];
    if (personIdsToAdd == nil) {
        self.error = self.addressBook.error;
        return NO;
    } else if (![self.infoStorage addContactInfoForPersonIds:personIdsToAdd contacts:contactsToAdd]) {
        self.error = self.infoStorage.error;
        return NO;
    }

    // 2. Update existing contacts.
    NSArray *updatedContacts = [self.infoStorage updateContactInfoForContacts:contacts];
    NSArray *personIdsToUpdate = [self.infoStorage personIdsForContacts:updatedContacts];
    if (![self.addressBook updatePersonWithIds:personIdsToUpdate contacts:updatedContacts]) {
        self.error = self.addressBook.error;
        return NO;
    }

    // 3. Remove stale contacts.
    NSArray *contactsToRemove = [storedContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:
            @"NOT (uid IN %@)", [contacts valueForKeyPath:@"@distinctUnionOfObjects.uid"]]];
    if (contactsToRemove != nil) {
        NSArray *personIdsToRemove = [self.infoStorage personIdsForContacts:contactsToRemove];
        if (personIdsToRemove == nil) {
            self.error = self.infoStorage.error;
            return NO;
        }

        if (![self.addressBook removePersonWithIds:personIdsToRemove]) {
            self.error = self.addressBook.error;
            return NO;
        } else if (![self.infoStorage removeContactInfoForPersonIds:personIdsToRemove]) {
            self.error = self.infoStorage.error;
            return NO;
        }
    }


    [self makeStorageConsistent];
    [EXAppSettings setContactsStorageVersion:[self currentContactStorageVersion]];
    [EXAppSettings setLastSyncDate:[NSDate date]];
    return YES;
}

- (BOOL)drop
{
    BOOL addressBookDroped = [self.addressBook drop];
    BOOL infoStorageDropped = [self.infoStorage drop];
    [EXAppSettings removeLastSyncDate];
    [EXAppSettings removeContactsStorageVersion];
    return addressBookDroped && infoStorageDropped;
}

#pragma mark - Private
/**
 * Remove contacts from address book and info storage if it not belongs to both storages.
 */
- (void)makeStorageConsistent
{
    NSArray *addressBookPersonIds = [self.addressBook allPersonIds];
    if (addressBookPersonIds != nil) {
        [self.infoStorage leaveContactInfoOnlyForPersonIds:addressBookPersonIds];
    }

    NSArray *infoStoragePersonIds = [self.infoStorage allPersonIds];
    if (infoStoragePersonIds != nil) {
        [self.addressBook leavePersonWithIds:infoStoragePersonIds];
    }
}

/**
 * @return Array of contacts (EXContact) with all defined fields.
 */
- (NSArray *)getStoredContacts
{
    NSArray *personIds = [self.addressBook allPersonIds];
    if (personIds == nil) {
        return nil;
    }

    NSArray *contacts = [self.addressBook contactsForPersonIds:personIds];
    [self.infoStorage readContactInfoForPersonIds:personIds toContacts:contacts];

    return contacts;
}

/**
 * @retrun Version of current storage.
 */
- (NSString *)currentContactStorageVersion
{
    return [EXAppSettings appVersion];
}

#pragma mark - Photos managing
- (void)invalidateAllPhotos
{
    [self.infoStorage makeUnsyncedAllPhotosUrl];
}

- (NSArray *)retreiveUnsyncedPhotosUrl
{
    return [self.infoStorage retreiveUnsyncedPhotosUrl];
}

- (void)syncPhoto:(NSData *)photo withUrl:(NSString *)url
{
    NSNumber *personId = [self.infoStorage personIdWithPhotoUrl:url];
    [self.addressBook setPhoto:photo forPerson:personId.intValue];
    [self.infoStorage makeSyncedPhotoUrl:url];
}

@end
