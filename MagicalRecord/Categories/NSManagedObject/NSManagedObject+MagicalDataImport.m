//
//  NSManagedObject+JSONHelpers.m
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import <objc/runtime.h>

void MR_swapMethodsFromClass(Class c, SEL orig, SEL new);

NSString * const kMagicalRecordImportCustomDateFormatKey            = @"dateFormat";
NSString * const kMagicalRecordImportDefaultDateFormatString        = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

NSString * const kMagicalRecordImportAttributeKeyMapKey             = @"mappedKeyName";
NSString * const kMagicalRecordImportAttributeValueClassNameKey     = @"attributeValueClassName";

NSString * const kMagicalRecordImportRelationshipMapKey             = @"mappedKeyName";
NSString * const kMagicalRecordImportRelationshipLinkedByKey        = @"relatedByAttribute";
NSString * const kMagicalRecordImportRelationshipTypeKey            = @"type";  //this needs to be revisited

NSString * const kMagicalRecordImportAttributeUseDefaultValueWhenNotPresent = @"useDefaultValueWhenNotPresent";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation NSManagedObject (MagicalRecord_DataImport)

- (BOOL) importValue:(id)value forKey:(NSString *)key
{
    NSString *selectorString = [NSString stringWithFormat:@"import%@:", [key capitalizedFirstCharacterString]];
    SEL selector = NSSelectorFromString(selectorString);
    if ([self respondsToSelector:selector])
    {
        [self performSelector:selector withObject:value];
        return YES;
    }
    return NO;
}

- (void) setAttributes:(NSDictionary *)attributes forKeysWithObject:(id)objectData
{    
    for (NSString *attributeName in attributes) 
    {
        NSAttributeDescription *attributeInfo = [attributes valueForKey:attributeName];
        NSString *lookupKeyPath = [objectData lookupKeyForAttribute:attributeInfo];
        
        if (lookupKeyPath) 
        {
            id value = [attributeInfo valueForKeyPath:lookupKeyPath fromObjectData:objectData];
            if (![self importValue:value forKey:attributeName])
            {
                [self setValue:value forKey:attributeName];
            }
        } 
        else 
        {
            if ([[[attributeInfo userInfo] objectForKey:kMagicalRecordImportAttributeUseDefaultValueWhenNotPresent] boolValue]) 
            {
                id value = [attributeInfo defaultValue];
                if (![self importValue:value forKey:attributeName])
                {
                    [self setValue:value forKey:attributeName];
                }
            }
        }
    }
}

- (NSManagedObject *) findObjectForRelationship:(NSRelationshipDescription *)relationshipInfo withData:(id)singleRelatedObjectData
{
    NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
    NSManagedObject *objectForRelationship = nil;
    id relatedValue = [singleRelatedObjectData relatedValueForRelationship:relationshipInfo];

    if (relatedValue) 
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        Class managedObjectClass = NSClassFromString([destinationEntity managedObjectClassName]);
        NSString *primaryKey = [relationshipInfo primaryKey];
        objectForRelationship = [managedObjectClass findFirstByAttribute:primaryKey
                                                               withValue:relatedValue
                                                               inContext:context];
    }

    return objectForRelationship;
}

- (void) addObject:(NSManagedObject *)relatedObject forRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSAssert2(relatedObject != nil, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), [relationshipInfo name]);    
    NSAssert2([relatedObject entity] == [relationshipInfo destinationEntity], @"related object entity %@ not same as destination entity %@", [relatedObject entity], [relationshipInfo destinationEntity]);

    //add related object to set
    NSString *addRelationMessageFormat = @"set%@:";
    id relationshipSource = self;
    if ([relationshipInfo isToMany]) 
    {
        addRelationMessageFormat = @"add%@Object:";
        if ([relationshipInfo respondsToSelector:@selector(isOrdered)] && [relationshipInfo isOrdered])
        {
            //Need to get the ordered set
            NSString *selectorName = [[relationshipInfo name] stringByAppendingString:@"Set"];
            relationshipSource = [self performSelector:NSSelectorFromString(selectorName)];
            addRelationMessageFormat = @"addObject:";
        }
    }

    NSString *addRelatedObjectToSetMessage = [NSString stringWithFormat:addRelationMessageFormat, attributeNameFromString([relationshipInfo name])];
 
    SEL selector = NSSelectorFromString(addRelatedObjectToSetMessage);
    
    @try 
    {
        [relationshipSource performSelector:selector withObject:relatedObject];        
    }
    @catch (NSException *exception) 
    {
        MRLog(@"Adding object for relationship failed: %@\n", relationshipInfo);
        MRLog(@"relatedObject.entity %@", [relatedObject entity]);
        MRLog(@"relationshipInfo.destinationEntity %@", [relationshipInfo destinationEntity]);
        MRLog(@"Add Relationship Selector: %@", addRelatedObjectToSetMessage);   
        MRLog(@"perform selector error: %@", exception);
    }
}

- (void) setRelationships:(NSDictionary *)relationships forKeysWithObject:(id)relationshipData withBlock:(void(^)(NSRelationshipDescription *,id))setRelationshipBlock
{
    for (NSString *relationshipName in relationships) 
    {
        if ([self importValue:relationshipData forKey:relationshipName]) 
        {
            continue;
        }
        
        NSRelationshipDescription *relationshipInfo = [relationships valueForKey:relationshipName];
        
        NSString *lookupKey = [[relationshipInfo userInfo] valueForKey:kMagicalRecordImportRelationshipMapKey] ?: relationshipName;
        id relatedObjectData = [relationshipData valueForKeyPath:lookupKey];
        
        if (relatedObjectData == nil || [relatedObjectData isEqual:[NSNull null]]) 
        {
            continue;
        }
        
        SEL shouldImportSelector = NSSelectorFromString([NSString stringWithFormat:@"shouldImport%@:", [relationshipName capitalizedFirstCharacterString]]);
        BOOL implementsShouldImport = (BOOL)[self respondsToSelector:shouldImportSelector];
        void (^establishRelationship)(NSRelationshipDescription *, id) = ^(NSRelationshipDescription *blockInfo, id blockData)
        {
            if (!(implementsShouldImport && !(BOOL)[self performSelector:shouldImportSelector withObject:relatedObjectData]))
            {
                setRelationshipBlock(blockInfo, blockData);
            }
        };
        
        if ([relationshipInfo isToMany] && [relatedObjectData isKindOfClass:[NSArray class]])
        {
            for (id singleRelatedObjectData in relatedObjectData) 
            {
                establishRelationship(relationshipInfo, singleRelatedObjectData);
            }
        }
        else
        {
            establishRelationship(relationshipInfo, relatedObjectData);
        }
    }
}

- (BOOL) preImport:(id)objectData;
{
    if ([self respondsToSelector:@selector(shouldImport:)])
    {
        BOOL shouldImport = (BOOL)[self performSelector:@selector(shouldImport:) withObject:objectData];
        if (!shouldImport) 
        {
            return NO;
        }
    }   

    if ([self respondsToSelector:@selector(willImport:)])
    {
        [self performSelector:@selector(willImport:) withObject:objectData];
    }
    MR_swapMethodsFromClass([objectData class], @selector(valueForUndefinedKey:), @selector(valueForUndefinedKey:));
    return YES;
}

- (BOOL) postImport:(id)objectData;
{
    MR_swapMethodsFromClass([objectData class], @selector(valueForUndefinedKey:), @selector(valueForUndefinedKey:));
    if ([self respondsToSelector:@selector(didImport:)])
    {
        [self performSelector:@selector(didImport:) withObject:objectData];
    }
    return YES;
}

- (BOOL) performDataImportFromObject:(id)objectData relationshipBlock:(void(^)(NSRelationshipDescription*, id))relationshipBlock;
{
    BOOL didStartimporting = [self preImport:objectData];
    if (!didStartimporting) return NO;
    
    NSDictionary *attributes = [[self entity] attributesByName];
    [self setAttributes:attributes forKeysWithObject:objectData];
    
    NSDictionary *relationships = [[self entity] relationshipsByName];
    [self setRelationships:relationships forKeysWithObject:objectData withBlock:relationshipBlock];
    
    return [self postImport:objectData];  
}

- (BOOL) importValuesForKeysWithObject:(id)objectData
{
    typeof(self) weakself = self;
    return [self performDataImportFromObject:objectData
                              relationshipBlock:^(NSRelationshipDescription *relationshipInfo, id localObjectData) {
        
        NSManagedObject *relatedObject = [weakself findObjectForRelationship:relationshipInfo withData:localObjectData];
        
        if (relatedObject == nil)
        {
            NSEntityDescription *entityDescription = [relationshipInfo destinationEntity];
            relatedObject = [entityDescription createInstanceInContext:[weakself managedObjectContext]];
        }
        [relatedObject importValuesForKeysWithObject:localObjectData];
        
        [weakself addObject:relatedObject forRelationship:relationshipInfo];
    } ];
}

+ (id) importFromObject:(id)objectData inContext:(NSManagedObjectContext *)context;
{
    NSAttributeDescription *primaryAttribute = [[self entityDescription] primaryAttributeToRelateBy];
    
    id value = [objectData valueForAttribute:primaryAttribute];
    
    NSManagedObject *managedObject = [self findFirstByAttribute:[primaryAttribute name] withValue:value inContext:context];
    if (managedObject == nil) 
    {
        managedObject = [self createInContext:context];
    }

    [managedObject importValuesForKeysWithObject:objectData];

    return managedObject;
}

+ (id) importFromObject:(id)objectData
{
    return [self importFromObject:objectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *) importFromArray:(NSArray *)listOfObjectData
{
    return [self importFromArray:listOfObjectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *) importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *objectIDs = [NSMutableArray array];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) 
    {    
        [listOfObjectData enumerateObjectsWithOptions:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
        {
            NSDictionary *objectData = (NSDictionary *)obj;

            NSManagedObject *dataObject = [self importFromObject:objectData inContext:localContext];

            if ([context obtainPermanentIDsForObjects:[NSArray arrayWithObject:dataObject] error:nil])
            {
              [objectIDs addObject:[dataObject objectID]];
            }
        }];
    }];
    
    return [self findAllWithPredicate:[NSPredicate predicateWithFormat:@"self IN %@", objectIDs] inContext:context];
}

@end

#pragma clang diagnostic pop

void MR_swapMethodsFromClass(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if (class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
    {
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else
    {
        method_exchangeImplementations(origMethod, newMethod);
    }
}
