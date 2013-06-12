//
//  NSManagedObject+JSONHelpers.h
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const kMagicalRecordImportCustomDateFormatKey;
extern NSString * const kMagicalRecordImportDefaultDateFormatString;
extern NSString * const kMagicalRecordImportAttributeKeyMapKey;
extern NSString * const kMagicalRecordImportAttributeValueClassNameKey;

extern NSString * const kMagicalRecordImportRelationshipMapKey;
extern NSString * const kMagicalRecordImportRelationshipLinkedByKey;
extern NSString * const kMagicalRecordImportRelationshipTypeKey;

@interface NSManagedObject (MagicalRecord_DataImport)

- (BOOL) importValuesForKeysWithObject:(id)objectData;

+ (id) importFromObject:(id)data;
+ (id) importFromObject:(id)data inContext:(NSManagedObjectContext *)context;

+ (NSArray *) importFromArray:(NSArray *)listOfObjectData;
+ (NSArray *) importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context;

@end
