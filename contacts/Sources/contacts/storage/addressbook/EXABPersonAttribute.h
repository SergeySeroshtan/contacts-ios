//
//  EXABPersonAttribute.h
//  contacts
//
//  Created by Sergey Seroshtan on 17.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AddressBook/AddressBook.h>

@interface EXABPersonAttribute : NSObject

- (id)initWithABPerson:(ABRecordRef)person;

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *mail;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *skype;
@property (strong, nonatomic) NSString *position;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSData *photo;

@end
