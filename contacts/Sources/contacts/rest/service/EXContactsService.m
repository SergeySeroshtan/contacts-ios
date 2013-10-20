//
//  EXContactsService.m
//  contacts
//
//  Created by Sergey Seroshtan on 08.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsService.h"

#import <RestKit/RestKit.h>
#import "RKObjectMappingOperationDataSource.h"
#import "RKMIMETypeSerialization.h"

#import <SSKeychain/SSKeychain.h>

#import "EXContact.h"
#import "EXContactsMapping.h"

#pragma mark - Public constants
NSString * const EXContactsServiceErrorDomain = @"com.exadel.donetsk.office-tools.contacts";
NSString * const kContactsServiceUrl = @"https://office-tools.donetsk.exadel.com/contacts/rest/";

#pragma mark - Private constants
static NSString * const kUserDefaults_MyContact = @"myContact";

/// Service name for persistant secure storage
static NSString * const kContactsServiceName = @"com.exadel.donetsk.office-tools.contacts";

@interface EXContactsService ()

@property (strong, nonatomic, readwrite) EXContact *signedUserContact;

@end

@implementation EXContactsService

#pragma mark - Initialization
+ (void)initialize
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:kContactsServiceUrl]];
    [RKObjectManager setSharedManager:objectManager];
}

#pragma mark - Authentication
- (void)signInUser:(NSString *)name password:(NSString *)password completion:(EXContactsServiceCompletion)completion
{
    PRECONDITION_ARG_NOT_NIL(name);
    PRECONDITION_ARG_NOT_NIL(password);
    PRECONDITION_ARG_NOT_NIL(completion);

    if ([self isUserSignedIn]) {
        [self signOut];
    }

    [[EXContactsService preparedObjectManagerWithUserName:name password:password] getObjectsAtPath:@"my.json"
            parameters:nil
        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
        {
            self.signedUserContact = [mappingResult firstObject];
            [SSKeychain setPassword:password forService:kContactsServiceName account:name];
            completion(YES, nil, nil);
        }
        failure:^(RKObjectRequestOperation *operation, NSError *error)
        {
            NSString *message = NSLocalizedString(@"Wrong user name or password.",
                    @"Error message: login authentication failed.");
            completion(NO, nil, [EXContactsService notAuthorizedError:message]);
        }
    ];
}

- (void)signOut
{
    NSString *userName = [self signedUserUid];
    if (userName != nil) {
        [SSKeychain deletePasswordForService:kContactsServiceName account:userName];
    }
}

#pragma mark - Accessors
- (void)setSignedUserContact:(EXContact *)signedUserContact
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (signedUserContact == nil) {
        [userDefaults removeObjectForKey:kUserDefaults_MyContact];
        return;
    }
    
    RKObjectMapping *contactMapping = [RKObjectMapping mappingForClass:[EXContact class]];
    [contactMapping addAttributeMappingsFromDictionary:[EXContactsMapping contactMapping]];
    
    NSMutableDictionary *contactDict = [NSMutableDictionary dictionary];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:signedUserContact
            destinationObject:contactDict mapping:contactMapping];
    [mappingOperation performMapping:nil];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:contactDict MIMEType:RKMIMETypeJSON error:nil];
    if (data == nil) {
        return;
    }
    
    [userDefaults setObject:data forKey:kUserDefaults_MyContact];
    [userDefaults synchronize];
}

- (EXContact *)signedUserContact
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *contactData = [userDefaults objectForKey:kUserDefaults_MyContact];
    if (contactData == nil) {
        return nil;
    }
    
    RKObjectMapping *contactMapping = [RKObjectMapping mappingForClass:[EXContact class]];
    [contactMapping addAttributeMappingsFromDictionary:[EXContactsMapping contactMapping]];
    
    id contactDict = [RKMIMETypeSerialization objectFromData:contactData MIMEType:RKMIMETypeJSON error:nil];
    EXContact *result = [[EXContact alloc] init];
    
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:contactDict
            destinationObject:result mapping:contactMapping];
    
    [mappingOperation performMapping:nil];
    
    return result;
}

#pragma mark - Authentication info
- (BOOL)isUserSignedIn
{
    return [self signedUserUid] != nil;
}

- (NSString *)signedUserUid
{
    NSDictionary *userAccount = [[SSKeychain accountsForService:kContactsServiceName] lastObject];
    NSString *userName = [userAccount objectForKey:kSSKeychainAccountKey];
    return [SSKeychain passwordForService:kContactsServiceName account:userName] != nil ? userName : nil;
}

#pragma mark - Service API
- (void)myContact:(EXContactsServiceCompletion)completion
{
    if (![self isUserSignedIn]) {
        completion(NO, nil, [EXContactsService notAuthorizedError]);
        return;
    }
    
    [[self preparedObjectManager] getObjectsAtPath:@"my.json" parameters:nil
        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
        {
            completion(YES, [mappingResult firstObject], nil);
        }
        failure:^(RKObjectRequestOperation *operation, NSError *error)
        {
            NSHTTPURLResponse *response =
                    [error.userInfo valueForKeyPath:AFNetworkingOperationFailingURLResponseErrorKey];
            static const int kStatusCode_NotAuthorized = 401;
            if (response == nil) {
                completion(NO, nil, [EXContactsService internalError]);
            } else if (response.statusCode == kStatusCode_NotAuthorized) {
                completion(NO, nil, [EXContactsService notAuthorizedError]);
            } else {
                completion(NO, nil, [EXContactsService notAvailableError]);
            }
            NSLog(@"Request my contact error: %@", error);
        }
    ];
}

- (void)coworkers:(EXContactsServiceCompletion)completion
{
    if (![self isUserSignedIn]) {
        completion(NO, nil, [EXContactsService notAuthorizedError]);
        return;
    }
    
    [[self preparedObjectManager] getObjectsAtPath:@"coworkers.json" parameters:nil
        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
        {
            completion(YES, [mappingResult array], nil);
        }
        failure:^(RKObjectRequestOperation *operation, NSError *error)
        {
            NSHTTPURLResponse *response =
                    [error.userInfo valueForKeyPath:AFNetworkingOperationFailingURLResponseErrorKey];
            static const int kStatusCode_NotAuthorized = 401;
            if (response == nil) {
                completion(NO, nil, [EXContactsService internalError]);
            } else if (response.statusCode == kStatusCode_NotAuthorized) {
                completion(NO, nil, [EXContactsService notAuthorizedError]);
            } else {
                completion(NO, nil, [EXContactsService notAvailableError]);
            }
            NSLog(@"Request coworkers error: %@", error);
        }
    ];
}

#pragma mark - Private
#pragma mark - Processing errors
/**
 * Creates error for this domain.
 */
+ (NSError *)createErrorWithCode:(EXContactsServiceErrorCode)code message:(NSString *)message
        userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *allUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    if (message != nil) {
        [allUserInfo setObject:message forKey:NSLocalizedDescriptionKey];
    }
    return [[NSError alloc] initWithDomain:EXContactsServiceErrorDomain code:code userInfo:allUserInfo];
}

/**
 * Creates NSError object, that describes 'not authorized' error.
 */
+ (NSError *)notAuthorizedError
{
    NSString *message = NSLocalizedString(@"User is not authorized.", @"Error message: User is not authorized.");
    return [self notAuthorizedError:message];
}
+ (NSError *)notAuthorizedError:(NSString *)errorMessage
{
    return [self notAuthorizedError:errorMessage userInfo:nil];
}
+ (NSError *)notAuthorizedError:(NSString *)errorMessage userInfo:(NSDictionary *)userInfo
{
    return [self createErrorWithCode:EXContactsServiceErrorCode_NotAuthorized message:errorMessage userInfo:userInfo];
}

/**
 * Creates NSError object, that describes 'not authorized' error.
 */
+ (NSError *)notAvailableError
{
    NSString *message = NSLocalizedString(@"Server is not available at this moment, try again later.",
            @"Error message: server is not available.");
    return [self notAvailableError:message];
}
+ (NSError *)notAvailableError:(NSString *)errorMessage
{
    return [self notAvailableError:errorMessage userInfo:nil];
}
+ (NSError *)notAvailableError:(NSString *)errorMessage userInfo:(NSDictionary *)userInfo
{
    return [self createErrorWithCode:EXContactsServiceErrorCode_NotAvailable message:errorMessage userInfo:userInfo];
}

/**
 * Creates NSError object, that describes 'not authorized' error.
 */
+ (NSError *)internalError
{
    NSString *message = NSLocalizedString(@"Internal error.", @"Error message: internal error.");
    return [self internalError:message];
}
+ (NSError *)internalError:(NSString *)errorMessage
{
    return [self internalError:errorMessage userInfo:nil];
}
+ (NSError *)internalError:(NSString *)errorMessage userInfo:(NSDictionary *)userInfo
{
    return [self createErrorWithCode:EXContactsServiceErrorCode_Internal message:errorMessage userInfo:userInfo];
}

#pragma mark - RestKit helpers
/**
 * Prepare RKObjectManager for getting data from this service as set authentication header, define success codes, etc.
 */
+ (RKObjectManager *)preparedObjectManagerWithUserName:(NSString *)userName password:(NSString *)userPassword
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[EXContact class]];
    [mapping addAttributeMappingsFromDictionary:[EXContactsMapping contactMapping]];
    
    RKResponseDescriptor *successResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
            method:RKRequestMethodGET pathPattern:nil keyPath:nil
            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager addResponseDescriptor:successResponseDescriptor];
    
    [objectManager.HTTPClient setAuthorizationHeaderWithUsername:userName password:userPassword];

    return objectManager;
}

- (RKObjectManager *)preparedObjectManager
{
    NSString *userName = [self signedUserUid];
    NSString *userPassword = [SSKeychain passwordForService:kContactsServiceName account:userName];
    return [EXContactsService preparedObjectManagerWithUserName:userName password:userPassword];
}

@end
