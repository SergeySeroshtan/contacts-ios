//
//  EXContactsService.h
//  contacts
//
//  Created by Sergey Seroshtan on 08.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EXContact;

// Service base URL.
extern NSString * const kContactsServiceUrl;

/// @name Errors description
extern NSString * const EXContactsServiceErrorDomain;
typedef enum {
    EXContactsServiceErrorCode_NotAuthorized = 100,
    EXContactsServiceErrorCode_NotAvailable = 200,
    EXContactsServiceErrorCode_Internal = 300
} EXContactsServiceErrorCode;

/// @name Callbacks
typedef void(^EXContactsServiceCompletion)(BOOL success, id data, NSError *error) ;

/**
 * This class provide interface to interact with 'Exadel Office Tools - Contacts' REST service.
 */
@interface EXContactsService : NSObject

/// @name Authentication
/**
 * Authenticate user in the service.
 */
- (void)signInUser:(NSString *)name password:(NSString *)password completion:(EXContactsServiceCompletion)completion;
/**
 * Remove user authentication info.
 */
- (void)signOut;

/// @name Authentication info
/**
 * @return YES if user is signed in, NO - otherwise.
 */
- (BOOL)isUserSignedIn;
/**
 * Contains valid user contact (EXContact) if user is signed in, nil - otherwise.
 */
@property (strong, nonatomic, readonly) EXContact *signedUserContact;

/// @name Service API
/**
 * Provide contact information about signed in user.
 * @return EXContact object in 'id' parameter of the 'completion' block, if success.
 */
- (void)myContact:(EXContactsServiceCompletion)completion;

/**
 * Provide contact information about coworkers of signed in user.
 * @return array of EXContact objects in 'id' parameter of the 'completion' block, if success.
 */
- (void)coworkers:(EXContactsServiceCompletion)completion;

@end
