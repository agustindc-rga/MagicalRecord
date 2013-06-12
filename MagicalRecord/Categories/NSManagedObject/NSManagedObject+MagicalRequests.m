//
//  NSManagedObject+MagicalRequests.m
//  Magical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObject+MagicalRequests.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalThreading.h"

@implementation NSManagedObject (MagicalRequests)


+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[self entityDescriptionInContext:context]];
    
    return request;
}

+ (NSFetchRequest *) createFetchRequest
{
	return [self createFetchRequestInContext:[NSManagedObjectContext contextForCurrentThread]];
}


+ (NSFetchRequest *) requestAll
{
	return [self createFetchRequestInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllInContext:(NSManagedObjectContext *)context
{
	return [self createFetchRequestInContext:context];
}

+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm;
{
    return [self requestAllWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self createFetchRequestInContext:context];
    [request setPredicate:searchTerm];
    
    return request;
}

+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value
{
    return [self requestAllWhere:property isEqualTo:value inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self createFetchRequestInContext:context];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", property, value]];
    
    return request;
}

+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm
{
    return [self requestFirstWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self createFetchRequestInContext:context];
    [request setPredicate:searchTerm];
    [request setFetchLimit:1];
    
    return request;
}

+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
{
    return [self requestFirstByAttribute:attribute withValue:searchValue inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self requestAllWhere:attribute isEqualTo:searchValue inContext:context]; 
    [request setFetchLimit:1];
    
    return request;
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
    return [self requestAllSortedBy:sortTerm
                             ascending:ascending
                         withPredicate:nil
                             inContext:context];
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self requestAllSortedBy:sortTerm
                             ascending:ascending
                             inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllInContext:context];
	if (searchTerm)
    {
        [request setPredicate:searchTerm];
    }
	[request setFetchBatchSize:[self defaultBatchSize]];
	
    NSMutableArray* sortDescriptors = [[NSMutableArray alloc] init];
    NSArray* sortKeys = [sortTerm componentsSeparatedByString:@","];
    for (NSString* sortKey in sortKeys) 
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
        [sortDescriptors addObject:sortDescriptor];
    }
    
	[request setSortDescriptors:sortDescriptors];
    
	return request;
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:searchTerm 
                                                inContext:[NSManagedObjectContext contextForCurrentThread]];
	return request;
}


@end
