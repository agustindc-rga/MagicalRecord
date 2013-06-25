//
//  NSManagedObject+MagicalAggregation.m
//  Magical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObject+MagicalAggregation.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalThreading.h"
#import "NSManagedObject+MagicalRequests.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObject+MagicalFinders.h"
#import "MagicalRecord+ErrorHandling.h"

@implementation NSManagedObject (MagicalAggregation)

#pragma mark -
#pragma mark Number of Entities

+ (NSNumber *) numberOfEntitiesWithContext:(NSManagedObjectContext *)context
{
	return [NSNumber numberWithUnsignedInteger:[self countOfEntitiesWithContext:context]];
}

+ (NSNumber *) numberOfEntities
{
	return [self numberOfEntitiesWithContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
    
	return [NSNumber numberWithUnsignedInteger:[self countOfEntitiesWithPredicate:searchTerm inContext:context]];
}

+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
{
	return [self numberOfEntitiesWithPredicate:searchTerm
                                        inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSUInteger) countOfEntities;
{
    return [self countOfEntitiesWithContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSUInteger) countOfEntitiesWithContext:(NSManagedObjectContext *)context;
{
	NSError *error = nil;
	NSUInteger count = [context countForFetchRequest:[self createFetchRequestInContext:context] error:&error];
	[MagicalRecord handleErrors:error];
	
    return count;
}

+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
{
    return [self countOfEntitiesWithPredicate:searchFilter inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter inContext:(NSManagedObjectContext *)context;
{
	NSError *error = nil;
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchFilter];
	
	NSUInteger count = [context countForFetchRequest:request error:&error];
	[MagicalRecord handleErrors:error];
    
    return count;
}

+ (NSUInteger) countOfEntitiesByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{
  NSPredicate *searchTerm = [NSPredicate predicateWithFormat:@"%K = %@", attribute, searchValue];
  return [self countOfEntitiesWithPredicate:searchTerm inContext:context];
}

+ (NSUInteger) countOfEntitiesByAttribute:(NSString *)attribute withValue:(id)searchValue
{
  return [self countOfEntitiesByAttribute:attribute withValue:searchValue inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (BOOL) hasAtLeastOneEntity
{
    return [self hasAtLeastOneEntityInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (BOOL) hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context
{
    return [[self numberOfEntitiesWithContext:context] intValue] > 0;
}

- (NSNumber *) maxValueFor:(NSString *)property
{
	NSManagedObject *obj = [[self class] findFirstByAttribute:property
                                                       withValue:[NSString stringWithFormat:@"max(%@)", property]];
	
	return [obj valueForKey:property];
}

- (id) objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [[self class] createFetchRequestInContext:context];
    
	NSPredicate *searchFor = [NSPredicate predicateWithFormat:@"SELF = %@ AND %K = min(%@)", self, property, property];
	[request setPredicate:searchFor];
	
	return [[self class] executeFetchRequestAndReturnFirstObject:request inContext:context];
}

- (id) objectWithMinValueFor:(NSString *)property
{
	return [self objectWithMinValueFor:property inContext:[self  managedObjectContext]];
}

+ (NSNumber *) aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context 
{
    NSExpression *ex = [NSExpression expressionForFunction:function 
                                                 arguments:[NSArray arrayWithObject:[NSExpression expressionForKeyPath:attributeName]]];
    
    NSExpressionDescription *ed = [[NSExpressionDescription alloc] init];
    [ed setName:@"result"];
    [ed setExpression:ex];
    
    // determine the type of attribute, required to set the expression return type    
    NSAttributeDescription *attributeDescription = [[[self entityDescription] attributesByName] objectForKey:attributeName];
    [ed setExpressionResultType:[attributeDescription attributeType]];    
    NSArray *properties = [NSArray arrayWithObject:ed];
    
    NSFetchRequest *request = [self requestAllWithPredicate:predicate inContext:context];
    [request setPropertiesToFetch:properties];
    [request setResultType:NSDictionaryResultType];    
    
    NSDictionary *resultsDictionary = [self executeFetchRequestAndReturnFirstObject:request inContext:context];
    NSNumber *resultValue = [resultsDictionary objectForKey:@"result"];
    
    return resultValue;    
}

+ (NSNumber *) aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate 
{
    return [self aggregateOperation:function 
                           onAttribute:attributeName 
                         withPredicate:predicate
                             inContext:[NSManagedObjectContext defaultContext]];    
}

@end
