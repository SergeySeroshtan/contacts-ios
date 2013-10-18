// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EXContactInfo.m instead.

#import "_EXContactInfo.h"

const struct EXContactInfoAttributes EXContactInfoAttributes = {
	.personId = @"personId",
	.photoSynced = @"photoSynced",
	.photoUrl = @"photoUrl",
	.uid = @"uid",
	.version = @"version",
};

const struct EXContactInfoRelationships EXContactInfoRelationships = {
};

const struct EXContactInfoFetchedProperties EXContactInfoFetchedProperties = {
};

@implementation EXContactInfoID
@end

@implementation _EXContactInfo

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ContactInfo" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ContactInfo";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ContactInfo" inManagedObjectContext:moc_];
}

- (EXContactInfoID*)objectID {
	return (EXContactInfoID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"personIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"personId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"photoSyncedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"photoSynced"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic personId;



- (int32_t)personIdValue {
	NSNumber *result = [self personId];
	return [result intValue];
}

- (void)setPersonIdValue:(int32_t)value_ {
	[self setPersonId:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitivePersonIdValue {
	NSNumber *result = [self primitivePersonId];
	return [result intValue];
}

- (void)setPrimitivePersonIdValue:(int32_t)value_ {
	[self setPrimitivePersonId:[NSNumber numberWithInt:value_]];
}





@dynamic photoSynced;



- (BOOL)photoSyncedValue {
	NSNumber *result = [self photoSynced];
	return [result boolValue];
}

- (void)setPhotoSyncedValue:(BOOL)value_ {
	[self setPhotoSynced:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitivePhotoSyncedValue {
	NSNumber *result = [self primitivePhotoSynced];
	return [result boolValue];
}

- (void)setPrimitivePhotoSyncedValue:(BOOL)value_ {
	[self setPrimitivePhotoSynced:[NSNumber numberWithBool:value_]];
}





@dynamic photoUrl;






@dynamic uid;






@dynamic version;











@end
