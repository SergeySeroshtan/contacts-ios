// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EXContactInfo.h instead.

#import <CoreData/CoreData.h>


extern const struct EXContactInfoAttributes {
	__unsafe_unretained NSString *personId;
	__unsafe_unretained NSString *photoSynced;
	__unsafe_unretained NSString *photoUrl;
	__unsafe_unretained NSString *uid;
	__unsafe_unretained NSString *version;
} EXContactInfoAttributes;

extern const struct EXContactInfoRelationships {
} EXContactInfoRelationships;

extern const struct EXContactInfoFetchedProperties {
} EXContactInfoFetchedProperties;








@interface EXContactInfoID : NSManagedObjectID {}
@end

@interface _EXContactInfo : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EXContactInfoID*)objectID;





@property (nonatomic, strong) NSNumber* personId;



@property int32_t personIdValue;
- (int32_t)personIdValue;
- (void)setPersonIdValue:(int32_t)value_;

//- (BOOL)validatePersonId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* photoSynced;



@property BOOL photoSyncedValue;
- (BOOL)photoSyncedValue;
- (void)setPhotoSyncedValue:(BOOL)value_;

//- (BOOL)validatePhotoSynced:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* photoUrl;



//- (BOOL)validatePhotoUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* uid;



//- (BOOL)validateUid:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* version;



//- (BOOL)validateVersion:(id*)value_ error:(NSError**)error_;






@end

@interface _EXContactInfo (CoreDataGeneratedAccessors)

@end

@interface _EXContactInfo (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitivePersonId;
- (void)setPrimitivePersonId:(NSNumber*)value;

- (int32_t)primitivePersonIdValue;
- (void)setPrimitivePersonIdValue:(int32_t)value_;




- (NSNumber*)primitivePhotoSynced;
- (void)setPrimitivePhotoSynced:(NSNumber*)value;

- (BOOL)primitivePhotoSyncedValue;
- (void)setPrimitivePhotoSyncedValue:(BOOL)value_;




- (NSString*)primitivePhotoUrl;
- (void)setPrimitivePhotoUrl:(NSString*)value;




- (NSString*)primitiveUid;
- (void)setPrimitiveUid:(NSString*)value;




- (NSString*)primitiveVersion;
- (void)setPrimitiveVersion:(NSString*)value;




@end
