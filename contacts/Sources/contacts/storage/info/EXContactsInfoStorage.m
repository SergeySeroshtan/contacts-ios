//
//  EXContactsInfoStorage.m
//  contacts
//
//  Created by Sergey Seroshtan on 16.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsInfoStorage.h"

#import <CoreData/CoreData.h>

#import "EXContact.h"
#import "EXContactInfo.h"

@interface EXContactsInfoStorage ()

@property (strong, nonatomic, readwrite) NSError *error;

@property (strong, nonatomic) NSManagedObjectContext *dataContext;
@property (assign, nonatomic, readwrite) BOOL isAccessible;

@end

@implementation EXContactsInfoStorage

#pragma mark - Initialization
- (id)init
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    if (self = [super init]) {
        [self initDataStorage];
    }
    return self;
}

#pragma mark - Info
- (NSArray *)allPersonIds
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_TRUE(self.isAccessible);
    return [[EXContactInfo allContactsInfoInContext:self.dataContext error:nil] valueForKeyPath:
            [NSString stringWithFormat:@"@unionOfObjects.%@", EXContactInfoAttributes.personId]];
}

- (NSArray *)personIdsForContacts:(NSArray *)contacts
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_TRUE(self.isAccessible);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:contacts.count];
    for (EXContact *contact in contacts) {
        EXContactInfo *contactInfo =
                [EXContactInfo findContactInfoByUid:contact.uid inContext:self.dataContext error:nil];
        if (contactInfo == nil) {
            break;
        }
        [result addObject:contactInfo.personId];
    }
    return result;
}

- (NSNumber *)personIdWithPhotoUrl:(NSString *)url
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(url);
    return [EXContactInfo findContactInfoByPhotoUrl:url inContext:self.dataContext error:NULL].personId;
}

- (BOOL)readContactInfoForPersonIds:(NSArray *)personIds toContacts:(NSArray *)contacts
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_ARG_NOT_NIL(contacts);
    PRECONDITION_TRUE(self.isAccessible);

    size_t readContactInfoCount = MIN(personIds.count, contacts.count);
    for (size_t pos = 0; pos < readContactInfoCount; ++pos) {
        EXContactInfo *contactInfo =
                [EXContactInfo findContactInfoByPersonId:personIds[pos] inContext:self.dataContext error:nil];
        if (contactInfo) {
            EXContact *contact = contacts[pos];
            contact.uid = contactInfo.uid;
            contact.version = contactInfo.version;
            contact.photoUrl = contactInfo.photoUrl;
        }
    }

    return YES;
}

#pragma mark - Managing
- (BOOL)addContactInfoForPersonIds:(NSArray *)personIds contacts:(NSArray *)contacts
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_ARG_NOT_NIL(contacts);
    PRECONDITION_TRUE(self.isAccessible);

    size_t addPersonCount = MIN(personIds.count, contacts.count);

    for (size_t pos = 0; pos < addPersonCount; ++pos) {
        EXContactInfo *contactInfo = [EXContactInfo insertInManagedObjectContext:self.dataContext];
        EXContact *contact = contacts[pos];
        contactInfo.personId = personIds[pos];
        contactInfo.uid = contact.uid;
        contactInfo.version = contact.version;
        contactInfo.photoUrl = contact.photoUrl;
        contactInfo.photoSyncedValue = NO;
    }

    return [self saveChanges];
}

- (NSArray *)updateContactInfoForContacts:(NSArray *)contacts
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(contacts);
    PRECONDITION_TRUE(self.isAccessible);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:contacts.count];
    for (EXContact *contact in contacts) {
        EXContactInfo *contactInfo =
                [EXContactInfo findContactInfoByUid:contact.uid inContext:self.dataContext error:nil];
        if (contactInfo) {
            if ([contactInfo.version isEqualToString:contact.version]) {
                continue;
            }
            contactInfo.uid = contact.uid;
            contactInfo.version = contact.version;
            if (![contactInfo.photoUrl isEqualToString:contact.photoUrl]) {
                contactInfo.photoUrl = contact.photoUrl;
                contactInfo.photoSyncedValue = NO;
            }
            [result addObject:contact];
        }
    }

    [self saveChanges];
    return result;
}

- (BOOL)removeContactInfoForPersonIds:(NSArray *)personIds
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_TRUE(self.isAccessible);
    for (NSNumber *personId in personIds) {
        EXContactInfo *contactInfo =
                [EXContactInfo findContactInfoByPersonId:personId inContext:self.dataContext error:nil];
        if (contactInfo) {
            [self.dataContext deleteObject:contactInfo];
        }
    }

    return [self saveChanges];
}

- (BOOL)leaveContactInfoOnlyForPersonIds:(NSArray *)personIds
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(personIds);
    PRECONDITION_TRUE(self.isAccessible);
    NSSet *personIdsSet = [NSSet setWithArray:personIds];
    for (EXContactInfo *contactInfo in [EXContactInfo allContactsInfoInContext:self.dataContext error:nil]) {
        if ([personIdsSet member:contactInfo.personId] == nil) {
            [self.dataContext deleteObject:contactInfo];
        }
    }
    return [self saveChanges];
}

- (BOOL)drop
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_TRUE(self.isAccessible);
    for (EXContactInfo *contactInfo in [EXContactInfo allContactsInfoInContext:self.dataContext error:nil]) {
        [self.dataContext deleteObject:contactInfo];
    }
    return [self saveChanges];
}

#pragma mark = Photos managing
- (void)makeUnsyncedAllPhotosUrl
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    NSArray *contactsInfo = [EXContactInfo findContactsInfoByPhotoSynced:YES inContext:self.dataContext error:nil];
    for (EXContactInfo *contactInfo in contactsInfo) {
        contactInfo.photoSyncedValue = NO;
    }
    [self.dataContext save:nil];
}

- (void)makeSyncedPhotoUrl:(NSString *)url
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    PRECONDITION_ARG_NOT_NIL(url);
    EXContactInfo *contactInfo = [EXContactInfo findContactInfoByPhotoUrl:url inContext:self.dataContext error:nil];
    contactInfo.photoSyncedValue = YES;
    [self.dataContext save:nil];
}

- (NSArray *)retreiveUnsyncedPhotosUrl
{
    PRECONDITION_TRUE([NSThread isMainThread]);
    NSArray *contactsInfo = [EXContactInfo findContactsInfoByPhotoSynced:NO inContext:self.dataContext error:nil];
    return [contactsInfo valueForKeyPath:
            [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", EXContactInfoAttributes.photoUrl]];
}

#pragma mark - Private
- (void)initDataStorage {
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"contacts" withExtension:@"momd"];
    NSManagedObjectModel *dataModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    if (dataModel == nil) {
        self.isAccessible = NO;
        return;
    }
	NSPersistentStoreCoordinator *dataStoreCoordinator =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: dataModel];

	NSURL *storeLocation = [[self applicationDocumentsDirectory] URLByAppendingPathComponent: @"contacts.sqlite"];
    NSError *error = nil;
    NSPersistentStore *dataStore = [dataStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
            configuration:nil URL:storeLocation options: nil error: &error];
    if (dataStore == nil) {
        self.isAccessible = NO;
        return;
    }

	self.dataContext = [[NSManagedObjectContext alloc] init];
	[self.dataContext setPersistentStoreCoordinator: dataStoreCoordinator];

    self.isAccessible = YES;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager]
			URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)saveChanges
{
    NSError *error = nil;
    [self.dataContext save:&error];
    if (error) {
        self.error = error;
        return NO;
    }
    return YES;
}


@end
