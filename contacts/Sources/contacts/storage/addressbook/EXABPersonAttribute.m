//
//  EXABPersonAttribute.m
//  contacts
//
//  Created by Sergey Seroshtan on 17.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXABPersonAttribute.h"

@interface EXABPersonAttribute ()

@property (assign, nonatomic) ABRecordRef person;

@end

@implementation EXABPersonAttribute

#pragma mark - Initialization
- (id)init
{
    PRECONDITION_TRUE(NO);
}

- (id)initWithABPerson:(ABRecordRef)person
{
    PRECONDITION_ARG_NOT_NIL(person);
    if (self = [super init]) {
        self.person = person;
    }
    return self;
}

#pragma mark - Accessors
- (NSString *)firstName
{
    return CFBridgingRelease(ABRecordCopyValue(self.person, kABPersonFirstNameProperty));
}

- (void)setFirstName:(NSString *)firstName
{
    if (firstName == nil) {
        [self removeFirstName];
        return;
    }
    ABRecordSetValue(self.person, kABPersonFirstNameProperty, (__bridge CFStringRef)firstName, NULL);
}

- (void)removeFirstName
{
    ABRecordRemoveValue(self.person, kABPersonFirstNameProperty, NULL);
}

- (NSString *)lastName
{
    return CFBridgingRelease(ABRecordCopyValue(self.person, kABPersonLastNameProperty));
}

- (void)setLastName:(NSString *)lastName
{
    if(lastName == nil) {
        [self removeLastName];
        return;
    }
    ABRecordSetValue(self.person, kABPersonLastNameProperty, (__bridge CFStringRef)lastName, NULL);
}

- (void)removeLastName
{
    ABRecordRemoveValue(self.person, kABPersonLastNameProperty, NULL);
}

- (NSString *)mail
{
    ABMultiValueRef emails = ABRecordCopyValue(self.person, kABPersonEmailProperty);
    @try {
        if (emails != NULL && ABMultiValueGetCount(emails) > 0) {
            return CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, 0));
        } else {
            return nil;
        }
    } @finally {
        CF_SAFE_RELEASE(emails);
    }
}

-(void)setMail:(NSString *)mail
{
    if (mail == nil) {
        [self removeMail];
        return;
    }
    ABMultiValueRef emails = ABRecordCopyValue(self.person, kABPersonEmailProperty);
    ABMutableMultiValueRef newEmails = emails == NULL ?
        ABMultiValueCreateMutable(kABMultiStringPropertyType) :
        ABMultiValueCreateMutableCopy(emails);
    CF_SAFE_RELEASE(emails);

    if (ABMultiValueGetCount(newEmails) > 0) {
        // Update email
        ABMultiValueReplaceValueAtIndex(newEmails, (__bridge CFStringRef)mail, 0);
    } else {
        // Add email
        ABMultiValueAddValueAndLabel(newEmails, (__bridge CFStringRef)mail, NULL, NULL);
    }
    ABRecordSetValue(self.person, kABPersonEmailProperty, newEmails, NULL);
    CF_SAFE_RELEASE(newEmails);
}

- (void)removeMail
{
    ABMultiValueRef emails = ABRecordCopyValue(self.person, kABPersonEmailProperty);
    if (emails != NULL && ABMultiValueGetCount(emails) > 0) {
        ABMutableMultiValueRef newEmails = ABMultiValueCreateMutableCopy(emails);
        ABMultiValueRemoveValueAndLabelAtIndex(newEmails, 0);
        ABRecordSetValue(self.person, kABPersonEmailProperty, newEmails, NULL);
        CF_SAFE_RELEASE(newEmails);
    }
    CF_SAFE_RELEASE(emails);
}

- (NSString *)phone
{
    ABMultiValueRef phones = ABRecordCopyValue(self.person, kABPersonPhoneProperty);
    @try {
        if (phones != NULL && ABMultiValueGetCount(phones) > 0) {
            return CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, 0));
        } else {
            return nil;
        }
    } @finally {
        CF_SAFE_RELEASE(phones);
    }
}

-(void)setPhone:(NSString *)phone
{
    if (phone == nil) {
        [self removePhone];
        return;
    }
    ABMultiValueRef phones = ABRecordCopyValue(self.person, kABPersonPhoneProperty);
    ABMutableMultiValueRef newPhones = phones == NULL ?
        ABMultiValueCreateMutable(kABMultiStringPropertyType) :
        ABMultiValueCreateMutableCopy(phones);
    CF_SAFE_RELEASE(phones);

    if (ABMultiValueGetCount(newPhones) > 0) {
        // Update email
        ABMultiValueReplaceValueAtIndex(newPhones, (__bridge CFStringRef)phone, 0);
    } else {
        // Add email
        ABMultiValueAddValueAndLabel(newPhones, (__bridge CFStringRef)phone, NULL, NULL);
    }
    ABRecordSetValue(self.person, kABPersonPhoneProperty, newPhones, NULL);
    CF_SAFE_RELEASE(newPhones);
}

- (void)removePhone
{
    ABMultiValueRef phones = ABRecordCopyValue(self.person, kABPersonPhoneProperty);
    if (phones != NULL && ABMultiValueGetCount(phones) > 0) {
        ABMutableMultiValueRef newPhones = ABMultiValueCreateMutableCopy(phones);
        ABMultiValueRemoveValueAndLabelAtIndex(newPhones, 0);
        ABRecordSetValue(self.person, kABPersonPhoneProperty, newPhones, NULL);
        CF_SAFE_RELEASE(newPhones);
    }
    CF_SAFE_RELEASE(phones);
}

- (NSString *)skype
{
    ABMultiValueRef im = ABRecordCopyValue(self.person, kABPersonInstantMessageProperty);
    CFDictionaryRef imService = NULL;
    @try {
        for (size_t pos = 0; pos < ABMultiValueGetCount(im); ++pos) {
            imService = ABMultiValueCopyValueAtIndex(im, pos);
            CFStringRef serviceKey = CFDictionaryGetValue(imService, kABPersonInstantMessageServiceKey);
            if (CFStringCompare(serviceKey, kABPersonInstantMessageServiceSkype, 0) == kCFCompareEqualTo) {
                return (__bridge NSString *)CFDictionaryGetValue(imService, kABPersonInstantMessageUsernameKey);
            }
            CF_SAFE_RELEASE(imService);
        }
    } @finally {
        CF_SAFE_RELEASE(im);
        CF_SAFE_RELEASE(imService);
    }
}

- (void)setSkype:(NSString *)skype
{
    if (skype == nil) {
        [self removeSkype];
        return;
    }

    // 1. Create new instant message record or get mutable copy of existing instant message record.
    ABMultiValueRef im = ABRecordCopyValue(self.person, kABPersonInstantMessageProperty);

    ABMutableMultiValueRef newIm = im == NULL ?
            ABMultiValueCreateMutable(kABMultiDictionaryPropertyType) :
            ABMultiValueCreateMutableCopy(im);

    CF_SAFE_RELEASE(im);

    // 2. Create new skype record
    CFMutableDictionaryRef newSkypeRecord = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 2, NULL, NULL);
    CFDictionaryAddValue(newSkypeRecord, kABPersonInstantMessageServiceKey, kABPersonInstantMessageServiceSkype);
    CFDictionaryAddValue(newSkypeRecord, kABPersonInstantMessageUsernameKey, (__bridge CFStringRef)skype);

    // 3. Try find and update existing skype record.
    BOOL skypeRecordWasUpdated = NO;
    for (size_t pos = 0; pos < ABMultiValueGetCount(newIm); ++pos) {
        CFDictionaryRef imService = ABMultiValueCopyValueAtIndex(newIm, pos);
        CFStringRef serviceKey = CFDictionaryGetValue(imService, kABPersonInstantMessageServiceKey);
        if (CFStringCompare(serviceKey, kABPersonInstantMessageServiceSkype, 0) == kCFCompareEqualTo) {
            ABMultiValueReplaceValueAtIndex(newIm, newSkypeRecord, pos);
            skypeRecordWasUpdated = YES;
            CF_SAFE_RELEASE(imService);
            break;
        }
        CF_SAFE_RELEASE(imService);
    }

    // 4. Add new skype record if it was not found.
    if (!skypeRecordWasUpdated) {
        ABMultiValueAddValueAndLabel(newIm, newSkypeRecord, NULL, NULL);
    }

    // 5. Save changes
    ABRecordSetValue(self.person, kABPersonInstantMessageProperty, newIm, NULL);

    CF_SAFE_RELEASE(newIm);
    CF_SAFE_RELEASE(newSkypeRecord);
}

- (void)removeSkype
{
    ABMultiValueRef im = ABRecordCopyValue(self.person, kABPersonInstantMessageProperty);
    if (im == NULL) {
        return;
    }

    ABMutableMultiValueRef newIm = ABMultiValueCreateMutableCopy(im);
    CF_SAFE_RELEASE(im);

    // Try find and update existing skype record.
    for (size_t pos = 0; pos < ABMultiValueGetCount(newIm); ++pos) {
        CFDictionaryRef imService = ABMultiValueCopyValueAtIndex(newIm, pos);
        CFStringRef serviceKey = CFDictionaryGetValue(imService, kABPersonInstantMessageServiceKey);
        if (CFStringCompare(serviceKey, kABPersonInstantMessageServiceSkype, 0) == kCFCompareEqualTo) {
            ABMultiValueRemoveValueAndLabelAtIndex(newIm, pos);
            CF_SAFE_RELEASE(imService);
            break;
        }
        CF_SAFE_RELEASE(imService);
    }

    // Save changes
    ABRecordSetValue(self.person, kABPersonInstantMessageProperty, newIm, NULL);

    CF_SAFE_RELEASE(newIm);
}

- (NSString *)position
{
    return CFBridgingRelease(ABRecordCopyValue(self.person, kABPersonJobTitleProperty));
}

- (void)setPosition:(NSString *)position
{
    if (position == nil) {
        [self removePosition];
        return;
    }
    ABRecordSetValue(self.person, kABPersonJobTitleProperty, (__bridge CFStringRef)position, NULL);
}

- (void)removePosition
{
    ABRecordRemoveValue(self.person, kABPersonJobTitleProperty, NULL);
}

- (NSString *)location
{
    ABMultiValueRef addresses = ABRecordCopyValue(self.person, kABPersonAddressProperty);
    CFDictionaryRef firstAddress = NULL;
    @try {
        if (ABMultiValueGetCount(addresses) > 0) {
            firstAddress = ABMultiValueCopyValueAtIndex(addresses, 0);
            return (__bridge NSString *)CFDictionaryGetValue(firstAddress, kABPersonAddressCityKey);
        }
    } @finally {
        CF_SAFE_RELEASE(addresses);
        CF_SAFE_RELEASE(firstAddress);
    }
}

- (void)setLocation:(NSString *)location
{
    if (location == nil) {
        [self removeLocation];
        return;
    }

    // 1. Create new addresses record or get mutable copy of existing iaddresses record.
    ABMultiValueRef addresses = ABRecordCopyValue(self.person, kABPersonAddressProperty);

    ABMutableMultiValueRef newAddresses = addresses == NULL ?
            ABMultiValueCreateMutable(kABMultiDictionaryPropertyType) :
            ABMultiValueCreateMutableCopy(addresses);

    CF_SAFE_RELEASE(addresses);

    // 2. Create new location record
    CFMutableDictionaryRef newLocationRecord = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 1, NULL, NULL);
    CFDictionaryAddValue(newLocationRecord, kABPersonAddressCityKey, (__bridge CFStringRef)location);

    // 3. Try find and update existing location record, or add new one.
    if (ABMultiValueGetCount(newAddresses) > 0) {
        ABMultiValueReplaceValueAtIndex(newAddresses, newLocationRecord, 0);
    } else {
        ABMultiValueAddValueAndLabel(newAddresses, newLocationRecord, NULL, NULL);
    }

    // 4. Save changes
    ABRecordSetValue(self.person, kABPersonAddressProperty, newAddresses, NULL);

    CF_SAFE_RELEASE(newAddresses);
    CF_SAFE_RELEASE(newLocationRecord);
}

- (void)removeLocation
{
    ABMultiValueRef addresses = ABRecordCopyValue(self.person, kABPersonAddressProperty);
    if (addresses == NULL) {
        return;
    }

    ABMutableMultiValueRef newAddresses = ABMultiValueCreateMutableCopy(addresses);
    CF_SAFE_RELEASE(addresses);

    // Remove existing location record.
    if (ABMultiValueGetCount(newAddresses) > 0) {
        ABMultiValueRemoveValueAndLabelAtIndex(newAddresses, 0);
    }

    // Save changes.
    ABRecordSetValue(self.person, kABPersonAddressProperty, newAddresses, NULL);

    CF_SAFE_RELEASE(newAddresses);
}

- (NSData *)photo
{
    return CFBridgingRelease(ABPersonCopyImageData(self.person));
}

- (void)setPhoto:(NSData *)photo
{
    if (photo == nil) {
        [self removePhoto];
        return;
    }
    ABPersonSetImageData(self.person, (__bridge CFDataRef)photo, NULL);
}

- (void)removePhoto
{
    ABPersonRemoveImageData(self.person, NULL);
}

@end
