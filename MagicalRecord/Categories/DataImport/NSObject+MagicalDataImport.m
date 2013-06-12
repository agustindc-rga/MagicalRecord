//
//  NSDictionary+MagicalDataImport.m
//  Magical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSObject+MagicalDataImport.h"
#import "NSManagedObject+MagicalDataImport.h"
#import "MagicalRecord.h"
#import "CoreData+MagicalRecord.h"

NSUInteger const kMagicalRecordImportMaximumAttributeFailoverDepth = 10;


@implementation NSObject (MagicalRecord_DataImport)

//#warning If you implement valueForUndefinedKey: in any NSObject in your code, this may be the problem if something broke
- (id) valueForUndefinedKey:(NSString *)key
{
    return nil;
}

- (NSString *) lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
{
    NSString *attributeName = [attributeInfo name];
    NSString *lookupKey = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportAttributeKeyMapKey] ?: attributeName;
    
    id value = [self valueForKeyPath:lookupKey];
    
    for (NSUInteger i = 1; i < kMagicalRecordImportMaximumAttributeFailoverDepth && value == nil; i++)
    {
        attributeName = [NSString stringWithFormat:@"%@.%lu", kMagicalRecordImportAttributeKeyMapKey, (unsigned long)i];
        lookupKey = [[attributeInfo userInfo] valueForKey:attributeName];
        if (lookupKey == nil) 
        {
            return nil;
        }
        value = [self valueForKeyPath:lookupKey];
    }
    
    return value != nil ? lookupKey : nil;
}

- (id) valueForAttribute:(NSAttributeDescription *)attributeInfo
{
    NSString *lookupKey = [self lookupKeyForAttribute:attributeInfo];
    return lookupKey ? [self valueForKeyPath:lookupKey] : nil;
}

- (NSString *) lookupKeyForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
    if (destinationEntity == nil) 
    {
        MRLog(@"Unable to find entity for type '%@'", [self valueForKey:kMagicalRecordImportRelationshipTypeKey]);
        return nil;
    }
    
    NSString *primaryKeyName = [relationshipInfo primaryKey];
    
    NSAttributeDescription *primaryKeyAttribute = [[destinationEntity attributesByName] valueForKey:primaryKeyName];
    NSString *lookupKey = [[primaryKeyAttribute userInfo] valueForKey:kMagicalRecordImportAttributeKeyMapKey] ?: [primaryKeyAttribute name];
    
    return lookupKey;
}

- (id) relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSString *lookupKey = [self lookupKeyForRelationship:relationshipInfo];
    return lookupKey ? [self valueForKeyPath:lookupKey] : nil;
}

@end
