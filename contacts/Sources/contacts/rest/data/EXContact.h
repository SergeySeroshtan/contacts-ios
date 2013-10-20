//
//  EXContact.h
//  contacts
//
//  Created by Sergey Seroshtan on 08.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Value-object for storing contact information about person.
 */
@interface EXContact : NSObject

@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *photoUrl;
@property (strong, nonatomic) NSString *mail;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *skype;
@property (strong, nonatomic) NSString *position;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *version;

@end
