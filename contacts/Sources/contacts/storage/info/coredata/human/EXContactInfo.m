#import "EXContactInfo.h"


@interface EXContactInfo ()

@end


@implementation EXContactInfo

+ (NSArray *)allContactsInfoInContext:(NSManagedObjectContext *)context error:(NSError **)error
{
    PRECONDITION_ARG_NOT_NIL(context);
    NSFetchRequest *allContactsInfoRequest = [[NSFetchRequest alloc] init];
    allContactsInfoRequest.entity = [EXContactInfo entityInManagedObjectContext:context];

    return [context executeFetchRequest:allContactsInfoRequest error:error];
}

+ (EXContactInfo *)findContactInfoByUid:(NSString *)uid inContext:(NSManagedObjectContext *)context
         error:(NSError **)error
{
    PRECONDITION_ARG_NOT_NIL(uid);
    PRECONDITION_ARG_NOT_NIL(context);
    NSFetchRequest *contactsInfoRequest = [[NSFetchRequest alloc] init];
    contactsInfoRequest.entity = [EXContactInfo entityInManagedObjectContext:context];
    contactsInfoRequest.predicate =
            [NSPredicate predicateWithFormat:@"%K LIKE %@", EXContactInfoAttributes.uid, uid];

    return [[context executeFetchRequest:contactsInfoRequest error:error] lastObject];
}

+ (EXContactInfo *)findContactInfoByPersonId:(NSNumber *)personId inContext:(NSManagedObjectContext *)context
         error:(NSError **)error
{
    PRECONDITION_ARG_NOT_NIL(personId);
    PRECONDITION_ARG_NOT_NIL(context);
    NSFetchRequest *contactsInfoRequest = [[NSFetchRequest alloc] init];
    contactsInfoRequest.entity = [EXContactInfo entityInManagedObjectContext:context];
    contactsInfoRequest.predicate =
            [NSPredicate predicateWithFormat:@"%K = %@", EXContactInfoAttributes.personId, personId];

    return [[context executeFetchRequest:contactsInfoRequest error:error] lastObject];
}

+ (EXContactInfo *)findContactInfoByPhotoUrl:(NSString *)url inContext:(NSManagedObjectContext *)context
        error:(NSError **)error
{
    PRECONDITION_ARG_NOT_NIL(url);
    PRECONDITION_ARG_NOT_NIL(context);
    NSFetchRequest *contactsInfoRequest = [[NSFetchRequest alloc] init];
    contactsInfoRequest.entity = [EXContactInfo entityInManagedObjectContext:context];
    contactsInfoRequest.predicate =
            [NSPredicate predicateWithFormat:@"%K = %@", EXContactInfoAttributes.photoUrl, url];

    return [[context executeFetchRequest:contactsInfoRequest error:error] lastObject];
}

+ (NSArray *)findContactsInfoByPhotoSynced:(BOOL)synced inContext:(NSManagedObjectContext *)context
        error:(NSError **)error
{
    PRECONDITION_ARG_NOT_NIL(context);
    NSFetchRequest *contactsInfoRequest = [[NSFetchRequest alloc] init];
    contactsInfoRequest.entity = [EXContactInfo entityInManagedObjectContext:context];
    contactsInfoRequest.predicate =
            [NSPredicate predicateWithFormat:@"%K = %@",
            EXContactInfoAttributes.photoSynced, [NSNumber numberWithBool:synced]];

    return [context executeFetchRequest:contactsInfoRequest error:error];
}

@end
