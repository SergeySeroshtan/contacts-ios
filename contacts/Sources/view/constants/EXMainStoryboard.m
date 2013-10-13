//
//  EXMainStoryboard.m
//  contacts
//
//  Created by Sergey Seroshtan on 10.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXMainStoryboard.h"

@implementation EXMainStoryboard

#pragma mark - ViewConroller identifiers
+ (NSString *)loginViewControllerId
{
    return @"LoginViewControllerId";
}

+ (NSString *)contactsNavigationControllerId
{
    return @"ContactsNavigationControllerId";
}

+ (NSString *)contactsViewControllerId
{
    return @"ContactsViewControllerId";
}

+ (NSString *)addressBookDeniedViewControllerId
{
    return @"AddressBookDeniedViewControllerId";
}

#pragma mark - Segue identifiers
+ (NSString *)loginToContactsNavigationViewControllerSegueId
{
    return @"LoginToContactsNavigationViewControllerSegueId";
}

+ (NSString *)contactsToLoginViewControllerSegueId
{
    return @"ContactsToLoginViewControllerSegueId";
}

+ (NSString *)addressBookDeniedToLoginViewControllerSegueId
{
    return @"AddressBookDeniedToLoginViewControllerSegueId";
}

+ (NSString *)addressBookDeniedToContactsNavigationViewControllerSegueId
{
    return @"AddressBookDeniedToContactsNavigationViewControllerSegueId";
}

@end
