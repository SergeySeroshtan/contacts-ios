//
//  EXMainStoryboard.m
//  contacts
//
//  Created by Sergey Seroshtan on 10.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXMainStoryboard.h"

@implementation EXMainStoryboard

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

+ (NSString *)loginToContactsViewControllerSegueId
{
    return @"LoginToContactsSegueId";
}

+ (NSString *)contactsToLoginViewControllerSegueId
{
    return @"ContactsToLoginSegueId";
}

@end
