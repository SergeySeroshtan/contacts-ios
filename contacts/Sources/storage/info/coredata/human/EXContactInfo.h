#import "_EXContactInfo.h"

@interface EXContactInfo : _EXContactInfo {}

/**
 *
 */
+ (NSArray *)allContactsInfoInContext:(NSManagedObjectContext *)context error:(NSError **)error;

/**
 *
 */
+ (EXContactInfo *)findContactInfoByUid:(NSString *)uid inContext:(NSManagedObjectContext *)context
         error:(NSError **)error;

/**
 *
 */
+ (EXContactInfo *)findContactInfoByPersonId:(NSNumber *)personId inContext:(NSManagedObjectContext *)context
         error:(NSError **)error;

@end
