//
//  EXContactsError.h
//  contacts
//
//  Created by Sergey Seroshtan on 22.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

/// @name Errors description
extern NSString * const EXContactsErrorDomain;
typedef enum {
    EXContactsErrorCode_NotAuthorized = 100,
    EXContactsErrorCode_NotAvailable = 200,
    EXContactsErrorCode_Internal = 300,
    EXContactsErrorCode_NoConnection = 400
} EXContactsErrorCode;

@interface EXContactsError : NSError

@end
