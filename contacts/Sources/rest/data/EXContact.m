//
//  EXContact.m
//  contacts
//
//  Created by Sergey Seroshtan on 08.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContact.h"

@implementation EXContact

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@>: {\n", NSStringFromClass([self class])];
    [description appendFormat:@"\tuid: %@,\n", self.uid];
    [description appendFormat:@"\tfirstName: %@,\n", self.firstName];
    [description appendFormat:@"\tlastName: %@,\n", self.lastName];
    [description appendFormat:@"\tphotoUrl: %@,\n", self.photoUrl];
    [description appendFormat:@"\tmail: %@,\n", self.mail];
    [description appendFormat:@"\tphone: %@,\n", self.phone];
    [description appendFormat:@"\tskype: %@,\n", self.skype];
    [description appendFormat:@"\tposition: %@,\n", self.position];
    [description appendFormat:@"\tlocation: %@,\n", self.location];
    [description appendFormat:@"\tversion: %@,\n", self.version];
    [description appendString:@"}"];
    return description;
}

@end
