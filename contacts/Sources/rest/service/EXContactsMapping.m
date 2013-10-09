//
//  EXContactsMapping.m
//  contacts
//
//  Created by Sergey Seroshtan on 08.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsMapping.h"

@implementation EXContactsMapping

+ (NSDictionary *)contactMapping
{
    return @{
        @"uid" : @"uid",
        @"firstName" : @"firstName",
        @"lastName" : @"lastName",
        @"photoUrl" : @"photoUrl",
        @"mail" : @"mail",
        @"phone" : @"phone",
        @"skype" : @"skype",
        @"position" : @"position",
        @"location" : @"location",
        @"version" : @"version",
    };
}

@end
