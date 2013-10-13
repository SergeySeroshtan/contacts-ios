//
//  EXContactsViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsViewController.h"

#import <AddressBook/AddressBook.h>

#import <MBProgressHUD/MBProgressHUD.h>
#import <SHActionSheetBlocks/SHActionSheetBlocks.h>
#import <SHAlertViewBlocks/SHAlertViewBlocks.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>
#import <FMDB/FMDatabaseAdditions.h>

#import "EXAlert.h"
#import "EXAppSettings.h"
#import "EXContactsService.h"
#import "EXMainStoryboard.h"

#define CF_RELEASE_SAFE(cfObj)\
        if (cfObj) {\
            CFRelease(cfObj);\
            cfObj = NULL;\
        }

#pragma mark - Address Book constants
static NSString * const kContactsGroupName = @"coworkers";

#pragma mark - Databse constatnts
static NSString * const kContactTableName = @"contact";

static NSString * const kContactTableColumn_Id = @"id";
static NSString * const kContactTableColumn_PersonId = @"personId";
static NSString * const kContactTableColumn_Uid = @"uid";
static NSString * const kContactTableColumn_Version = @"version";
static NSString * const kContactTableColumn_PhotoUrl = @"photoUrl";
static NSString * const kContactTableColumn_PhotoSynced = @"photoSynced";

@interface EXContactsViewController () <UIActionSheetDelegate>

@property (strong, nonatomic) NSDateFormatter *lastSyncDateFormatter;
@property (strong, nonatomic) FMDatabase *contactsDb;

@end

@implementation EXContactsViewController

#pragma mark - UI lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.lastSyncDateFormatter  = [[NSDateFormatter alloc] init];
    [self.lastSyncDateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss"];

    self.contactsDb = [[FMDatabase alloc] initWithPath:[self getContactsDatabasePath]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

#pragma mark - UI actions
- (void)removeAccount
{
    NSString *cancelButtonTitle =
            NSLocalizedString(@"Cancel", @"Remove account confirmation alert | Cancel button title.");

    NSString *confirmationTitle =
            NSLocalizedString(@"Attention", @"Remove account confirmation alert | Title");

    NSString *removeAccountButtonTitle =
            NSLocalizedString(@"Remove", @"Remove account confirmation alert | Remove account button title");

    NSString *confirmationMessage =
            NSLocalizedString(@"Removing account will also remove all contacts from your address book!",
                    @"Remove account confirmation alert | Message");

    UIAlertView *confirmation = [UIAlertView SH_alertViewWithTitle:confirmationTitle
        andMessage:confirmationMessage buttonTitles:@[removeAccountButtonTitle]
        cancelTitle:cancelButtonTitle withBlock:^(NSInteger buttonIndex) {
            const NSInteger removeAccountButtonIndex = 1;
            if (buttonIndex == removeAccountButtonIndex) {
                [self dropAddressBookRelatedPersons];
                [self dropContactsDatabase];
                [EXAppSettings removeLastSyncDate];
                [EXAppSettings removeContactsDatabaseVersion];
                [EXContactsService signOut];
                [self performSegueWithIdentifier:[EXMainStoryboard contactsToLoginViewControllerSegueId]
                        sender:self.view];
            }
        }];
    [confirmation show];
}

- (IBAction)changeAccount:(id)sender {
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Edit view | Change sheet | Cancel button title.");
    NSString *removeAccountButtonTitle =
            NSLocalizedString(@"Remove account", @"Edit view | Change sheet | Remove account button title.");

    UIActionSheet *changeAccountSheet = [UIActionSheet SH_actionSheetWithTitle:nil buttonTitles:nil
        cancelTitle:cancelButtonTitle destructiveTitle:removeAccountButtonTitle
        withBlock:^(NSInteger buttonIndex)
        {
            const NSInteger removeAccountButtonIndex = 0;
            if (buttonIndex == removeAccountButtonIndex) {
                [self removeAccount];
            }
        }
    ];
    [changeAccountSheet showInView:self.view];
}

- (IBAction)syncContacts:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Loading contacts", @"Hud title | Loading contacts");
    [EXContactsService
        coworkers:^(BOOL success, id data, NSError *error)
        {
            if (success) {
                hud.labelText = NSLocalizedString(@"Updating contacts", @"Hud title | Updating contacts");
                [self updateContacts:data];
                [EXAppSettings setLastSyncDate:[NSDate date]];
                [EXAppSettings setContactsDatabaseVersion:[EXAppSettings appVersion]];
                [self updateUI];
                [hud hide:YES];
            } else {
                [hud hide:YES];
                [EXAlert showWithMessage:[error localizedDescription] errorLevel:EXAlertErrorLevel_Fail];
            }
        }
    ];
}

#pragma mark - Private
#pragma mark - Address book interaction
- (void)updateContacts:(NSArray *)contacts
{
    NSAssert(ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized,
            @"Address book  should be accessible at this point");

    // Open contacts database
    if (![self.contactsDb open]) {
        NSLog(@"Can not access contacts database.");
        return;
    }

    // Create table if needed
    if (![self.contactsDb tableExists:kContactTableName]) {
        NSMutableString *createTableQuery = [NSMutableString stringWithFormat:@"CREATE TABLE %@", kContactTableName];
        [createTableQuery appendFormat:@" (%@ INTEGER PRIMARY KEY ASC AUTOINCREMENT", kContactTableColumn_Id];
        [createTableQuery appendFormat:@", %@ TEXT NOT NULL UNIQUE ON CONFLICT REPLACE", kContactTableColumn_PersonId];
        [createTableQuery appendFormat:@", %@ TEXT NOT NULL UNIQUE ON CONFLICT REPLACE", kContactTableColumn_Uid];
        [createTableQuery appendFormat:@", %@ TEXT NOT NULL", kContactTableColumn_Version];
        [createTableQuery appendFormat:@", %@ TEXT", kContactTableColumn_PhotoUrl];
        [createTableQuery appendFormat:@", %@ INTEGER NOT NULL DEFAULT 0)", kContactTableColumn_PhotoSynced];
        
        BOOL result = [self.contactsDb executeUpdate:createTableQuery];

        if (!result) {
            NSLog(@"Can not create table in database.");
            return;
        }
    }

    NSMutableArray *newContacts = [NSMutableArray arrayWithArray:contacts];
    ABAddressBookRef addressBook = NULL;
    ABRecordRef coworkersGroup = NULL;
    @try {
        // 1. Get access to address book
        {
            CFErrorRef addressBookError = NULL;
            addressBook = ABAddressBookCreateWithOptions(NULL, &addressBookError);
            if (addressBookError) {
                [self handleAddressBookError:addressBookError];
                CFRelease(addressBookError);
                addressBookError = NULL;
                return;
            }
        }

        // 2. Get group if exists, or create it otherwise
        NSArray *groups = CFBridgingRelease(ABAddressBookCopyArrayOfAllGroups(addressBook));
        for (size_t pos = 0; pos < groups.count; ++pos) {
            ABRecordRef group = (__bridge ABRecordRef)groups[pos];
            NSString *groupName = CFBridgingRelease(ABRecordCopyValue(group, kABGroupNameProperty));
            if ([groupName isEqualToString:kContactsGroupName]) {
                coworkersGroup = CFRetain(group);
                break;
            }
        }

        if (coworkersGroup == NULL) {
            coworkersGroup = ABGroupCreate();
            ABRecordSetValue(coworkersGroup, kABGroupNameProperty, (__bridge CFStringRef)kContactsGroupName, NULL);
            ABAddressBookAddRecord(addressBook, coworkersGroup, NULL);
            ABAddressBookSave(addressBook, NULL);
        }

        // 3. Define is update should be forced
        BOOL forceUpdate = [EXAppSettings contactsDatabaseVersion] != nil &&
                [[EXAppSettings contactsDatabaseVersion] isEqualToString:[EXAppSettings appVersion]] == NO;

        // 4. Read existing contacts from address book (persons)
        NSArray *existingPersons = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(coworkersGroup));

        // 5. Update or remove stale contacts
        for (size_t pos = 0; pos < existingPersons.count; ++pos) {
            ABRecordRef oldPerson = (__bridge ABRecordRef)existingPersons[pos];
            // Find record in received contacts
            EXContact *oldContact = [self createContactFromAddressBookPerson:oldPerson];
            [self addUtilInformationForPerson:oldPerson toContact:oldContact fromDatabase:self.contactsDb];
            EXContact *newContact = [[contacts filteredArrayUsingPredicate:
                    [NSPredicate predicateWithFormat:@"uid = %@", oldContact.uid]] firstObject];
            if (newContact == nil) {
                // Record is stale, should be removed.
                ABAddressBookRemoveRecord(addressBook, oldPerson, NULL);
            } else {
                // TODO: Remove next line when else section will be implemented.
                forceUpdate = YES;
                // Person Record should be updated
                if (forceUpdate || ![oldContact.version isEqualToString:newContact.version]) {
                    // Force update
                    ABRecordRef newPerson = [self createAddressBookPersonFromContact:newContact];
                    ABAddressBookRemoveRecord(addressBook, oldPerson, NULL);
                    ABAddressBookAddRecord(addressBook, newPerson, NULL);
                    ABGroupAddMember(coworkersGroup, newPerson, NULL);
                    ABAddressBookSave(addressBook, NULL);
                    [self updateContactsDatabseWithAddressBookPerson:newPerson andContact:newContact];
                } else {
                    ABRecordRef updatedPerson = [self updateAddressBookPerson:oldPerson withContact:newContact];
                    [self updateContactsDatabseWithAddressBookPerson:updatedPerson andContact:newContact];
                }
                [newContacts removeObject:newContact];
            }
        }

        // 6. Add new contacts
        for (EXContact *contact in newContacts) {
            ABRecordRef person = [self createAddressBookPersonFromContact:contact];
            ABAddressBookAddRecord(addressBook, person, NULL);
            ABGroupAddMember(coworkersGroup, person, NULL);
            ABAddressBookSave(addressBook, NULL);
            [self updateContactsDatabseWithAddressBookPerson:person andContact:contact];
            CFRelease(person);
        }
    } @finally {
        if (addressBook) {
            CFRelease(addressBook);
            addressBook = NULL;
        }
        if (coworkersGroup) {
            CFRelease(coworkersGroup);
            coworkersGroup = NULL;
        }
        [self.contactsDb close];
    }
}


#pragma mark - UI helpers
/**
 * Updates all UI components.
 */
- (void)updateUI
{
    self.userNameLabel.text = [EXContactsService signedUserName];
    NSDate *lastSyncDate = [EXAppSettings lastSyncDate];
    NSString *lastSyncDateString =
            lastSyncDate != nil ? [self.lastSyncDateFormatter stringFromDate:lastSyncDate] : @"undefined";
    self.lastSyncDateLabel.text = lastSyncDateString;
}

#pragma mark - Address Book
- (void)handleAddressBookError:(CFErrorRef)error
{
    CFIndex errorCode = CFErrorGetCode(error);
    NSString *errorMessage = NSLocalizedString(@"Can not access address book due to undefined reason.",
                                               @"Address book | Error message | Unknown reason.");
    if (errorCode == kABOperationNotPermittedByStoreError) {
        errorMessage = NSLocalizedString(@"Can not access address book. Not permitted by store.",
                                         @"Address book | Error message | Not permitted by store.");
    } else if (errorCode == kABOperationNotPermittedByUserError) {
        errorMessage = NSLocalizedString(@"Can not access address book. Not permitted by user.",
                                         @"Address book | Error message | Not permitted by user.");
    }
    [EXAlert showWithMessage:errorMessage errorLevel:EXAlertErrorLevel_Error];
}

- (BOOL)replaceAddressBookOldPerson:(ABRecordRef)oldPerson withNewPerson:(ABRecordRef)newPerson
{
    return NO;
}

- (ABRecordRef)updateAddressBookPerson:(ABRecordRef)person withContact:(EXContact *)contact
{
    return NULL;
}



#pragma mark - Contacts database management
- (NSString *)getContactsDatabasePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *homeDir = ([paths count] > 0) ? paths[0] : nil;
    return [homeDir stringByAppendingPathComponent:@"contacts.db"];
}

- (EXContact *)createContactFromAddressBookPerson:(ABRecordRef)person
{
    PRECONDITION_ARG_NOT_NIL(person);
    
    EXContact *contact = [[EXContact alloc] init];
    
    // First name
    contact.firstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    // Last name
    contact.lastName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
    // E-mail
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 0) {
        contact.mail = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, 0));
    }
    CFRelease(emails);
    
    // Phone
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phones) > 0) {
        contact.phone = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, 0));
    }
    CFRelease(phones);
    
    // Skype
    ABMultiValueRef im = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
    NSArray *imDictionaries = CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(im));
    for (size_t pos = 0; pos < imDictionaries.count; ++pos) {
        CFDictionaryRef specificIm = (__bridge CFDictionaryRef)imDictionaries[pos];
        CFStringRef serviceKey = CFDictionaryGetValue(specificIm, kABPersonInstantMessageServiceKey);
        if (CFStringCompare(serviceKey, kABPersonInstantMessageServiceSkype, 0) == kCFCompareEqualTo) {
            contact.skype = (__bridge NSString *)CFDictionaryGetValue(specificIm, kABPersonInstantMessageUsernameKey);
            break;
        }
    }
    CFRelease(im);
    
    // Position
    contact.position = CFBridgingRelease(ABRecordCopyValue(person, kABPersonJobTitleProperty));

    // Location
    ABMultiValueRef addresses = ABRecordCopyValue(person, kABPersonAddressProperty);
    if (ABMultiValueGetCount(addresses) > 0) {
        CFDictionaryRef firstAddress = ABMultiValueCopyValueAtIndex(addresses, 0);
        contact.location = (__bridge NSString *)CFDictionaryGetValue(firstAddress, kABPersonAddressCityKey);
        CFRelease(firstAddress);
    }
    CFRelease(addresses);
    
    return contact;
}

- (ABRecordRef)createAddressBookPersonFromContact:(EXContact *)contact
{
    PRECONDITION_ARG_NOT_NIL(contact);
    
    ABRecordRef person = ABPersonCreate();
    CFErrorRef error = NULL;
    // First name
    ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef)contact.firstName, &error);
    // Last name
    ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFStringRef)contact.lastName, &error);
    // E-mail
    ABMultiValueRef emails = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(emails, (__bridge CFStringRef)contact.mail, NULL, NULL);
    ABRecordSetValue(person, kABPersonEmailProperty, emails, &error);
    CFRelease(emails);
    // Phone
    ABMultiValueRef phones = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(phones, (__bridge CFStringRef)contact.phone, kABPersonPhoneMobileLabel, NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, phones, &error);
    CFRelease(phones);
    // Skype
    CFMutableDictionaryRef skype = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 2, NULL, NULL);
    CFDictionaryAddValue(skype, kABPersonInstantMessageServiceKey, kABPersonInstantMessageServiceSkype);
    CFDictionaryAddValue(skype, kABPersonInstantMessageUsernameKey, (__bridge CFStringRef)contact.skype);
    // Skype to IM
    ABMultiValueRef im = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    ABMultiValueAddValueAndLabel(im, skype, NULL, NULL);
    ABRecordSetValue(person, kABPersonInstantMessageProperty, im, &error);
    CFRelease(skype);
    CFRelease(im);
    // Position (Job Title)
    ABRecordSetValue(person, kABPersonJobTitleProperty, (__bridge CFStringRef)contact.position, &error);
    // Location
    CFMutableDictionaryRef location = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 1, NULL, NULL);
    CFDictionaryAddValue(location, kABPersonAddressCityKey, (__bridge CFStringRef)contact.location);
    // Location to Address
    ABMultiValueRef address = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    ABMultiValueAddValueAndLabel(address, location, NULL, NULL);
    ABRecordSetValue(person, kABPersonAddressProperty, address, &error);

    NSAssert(error == NULL, @"Person properties should be set correctly");
    return person;
}

- (BOOL)updateContactsDatabseWithAddressBookPerson:(ABRecordRef)person andContact:(EXContact *)contact
{
    PRECONDITION_ARG_NOT_NIL(person);
    PRECONDITION_ARG_NOT_NIL(contact);
    NSNumber *personId = [NSNumber numberWithInteger:ABRecordGetRecordID(person)];
    
    NSMutableString *insertQuery = [NSMutableString stringWithFormat:@"INSERT INTO %@", kContactTableName];
    [insertQuery appendFormat:@" (%@, %@, %@, %@)",
            kContactTableColumn_PersonId, kContactTableColumn_Uid, kContactTableColumn_Version,
            kContactTableColumn_PhotoUrl];
    [insertQuery appendFormat:@" VALUES (?, ?, ?, ?)"];
    
    return [self.contactsDb executeUpdate:insertQuery, personId, contact.uid, contact.version, contact.photoUrl];
}

- (void)addUtilInformationForPerson:(ABRecordRef)person toContact:(EXContact *)contact fromDatabase:(FMDatabase *)db
{
    PRECONDITION_ARG_NOT_NIL(person);
    PRECONDITION_ARG_NOT_NIL(db);

    NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID(person)];
    NSString *contactQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
            kContactTableName, kContactTableColumn_PersonId];
    FMResultSet *dbResult = [db executeQuery:contactQuery, recordId];
    if ([dbResult next]) {
        contact.uid = [dbResult stringForColumn:kContactTableColumn_Uid];
        contact.version = [dbResult stringForColumn:kContactTableColumn_Version];
        contact.photoUrl = [dbResult stringForColumn:kContactTableColumn_PhotoUrl];
    }
}

- (void)dropAddressBookRelatedPersons
{
    // 1. Get address book
    CFErrorRef addressBookError = NULL;
    ABAddressBookRef addressBook = NULL;
    ABRecordRef coworkersGroup = NULL;
    
    @try {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &addressBookError);
        if (addressBookError) {
            [self handleAddressBookError:addressBookError];
            return;
        }
        
        // 2. Get group
        NSArray *groups = CFBridgingRelease(ABAddressBookCopyArrayOfAllGroups(addressBook));
        for (size_t pos = 0; pos < groups.count; ++pos) {
            ABRecordRef group = (__bridge ABRecordRef)groups[pos];
            NSString *groupName = CFBridgingRelease(ABRecordCopyValue(group, kABGroupNameProperty));
            if ([groupName isEqualToString:kContactsGroupName]) {
                coworkersGroup = CFRetain(group);
                break;
            }
        }
        
        // 3. Remove persons and group
        if (coworkersGroup) {
            NSArray *persons = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(coworkersGroup));
            for (size_t pos = 0; pos < persons.count; ++pos) {
                ABRecordRef person = (__bridge ABRecordRef)persons[pos];
                ABAddressBookRemoveRecord(addressBook, person, NULL);
            }
            ABAddressBookRemoveRecord(addressBook, coworkersGroup, NULL);
            ABAddressBookSave(addressBook, NULL);
        }
    } @finally {
        CF_RELEASE_SAFE(addressBook);
        CF_RELEASE_SAFE(addressBookError);
        CF_RELEASE_SAFE(coworkersGroup);
    }
}

- (void)dropContactsDatabase
{
    if(![self.contactsDb open]) {
        return;
    }
    
    if ([self.contactsDb tableExists:kContactTableName]) {
        NSString *dropContactTableQuery = [NSString stringWithFormat:@"DROP TABLE %@", kContactTableName];
        [self.contactsDb executeUpdate:dropContactTableQuery];
    }
    
    [self.contactsDb close];
}

@end