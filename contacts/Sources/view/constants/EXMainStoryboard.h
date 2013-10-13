//
//  EXMainStoryboard.h
//  contacts
//
//  Created by Sergey Seroshtan on 10.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EXMainStoryboard : NSObject

/// @name UIViewController identifiers
+ (NSString *)loginViewControllerId;
+ (NSString *)contactsNavigationControllerId;
+ (NSString *)contactsViewControllerId;
+ (NSString *)addressBookDeniedViewControllerId;

/// @name Segue identifiers
+ (NSString *)loginToContactsNavigationViewControllerSegueId;
+ (NSString *)contactsToLoginViewControllerSegueId;
+ (NSString *)addressBookDeniedToLoginViewControllerSegueId;
+ (NSString *)addressBookDeniedToContactsNavigationViewControllerSegueId;

@end
