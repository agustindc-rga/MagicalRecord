    //
//  NSManagedObject+MagicalFinders.m
//  Magical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObject+MagicalFinders.h"
#import "NSManagedObject+MagicalRequests.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalThreading.h"

@implementation NSManagedObject (MagicalFinders)

#pragma mark - Find All

+ (NSArray *) findAllInContext:(NSManagedObjectContext *)context
{
	return [self executeFetchRequest:[self requestAllInContext:context] inContext:context];
}

+ (NSArray *) findAll
{
	return [self findAllInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm ascending:ascending inContext:context];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self findAllSortedBy:sortTerm
                          ascending:ascending 
                          inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:searchTerm
                                                inContext:context];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm
{
	return [self findAllSortedBy:sortTerm
                          ascending:ascending
                      withPredicate:searchTerm 
                          inContext:[NSManagedObjectContext contextForCurrentThread]];
}


+ (NSArray *) findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findAllWithPredicate:(NSPredicate *)searchTerm
{
	return [self findAllWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

#pragma mark - Find All With Attributes

+ (NSArray *) findAllAndRetrieveAttributes:(NSArray*)attributes
{
    return [self findAllAndRetrieveAttributes:attributes inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllAndRetrieveAttributes:(NSArray*)attributes inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestAllInContext:context];
    [request setPropertiesToFetch:attributes];
    [request setResultType:NSDictionaryResultType];
    
    return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findAllWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes
{
    return [self findAllWithPredicate:searchTerm andRetrieveAttributes:attributes inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestAllWithPredicate:searchTerm inContext:context];
    [request setPropertiesToFetch:attributes];
    [request setResultType:NSDictionaryResultType];
    
    return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue andRetrieveAttributes:(NSArray *)attributes
{
    return [self findByAttribute:attribute withValue:searchValue andRetrieveAttributes:attributes inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestAllWhere:attribute isEqualTo:searchValue inContext:context];
    [request setPropertiesToFetch:attributes];
    [request setResultType:NSDictionaryResultType];
    
    return [self executeFetchRequest:request inContext:context];
}

#pragma mark - Find First

+ (id) findFirstInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirst
{
	return [self findFirstInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{	
	NSFetchRequest *request = [self requestFirstByAttribute:attribute withValue:searchValue inContext:context];
    //    [request setPropertiesToFetch:[NSArray arrayWithObject:attribute]];
    
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue
{
	return [self findFirstByAttribute:attribute
                               withValue:searchValue 
                               inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstOrderedByAttribute:(NSString *)attribute ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self requestAllSortedBy:attribute ascending:ascending inContext:context];
    [request setFetchLimit:1];

    return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirstOrderedByAttribute:(NSString *)attribute ascending:(BOOL)ascending;
{
    return [self findFirstOrderedByAttribute:attribute
                                      ascending:ascending
                                      inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchTerm
{
    return [self findFirstWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestFirstWithPredicate:searchTerm inContext:context];
    
    return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:property ascending:ascending withPredicate:searchterm inContext:context];
    
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending
{
	return [self findFirstWithPredicate:searchterm
                                  sortedBy:property 
                                 ascending:ascending 
                                 inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	[request setPropertiesToFetch:attributes];
	
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes
{
	return [self findFirstWithPredicate:searchTerm
                     andRetrieveAttributes:attributes 
                                 inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ...
{
	NSFetchRequest *request = [self requestAllSortedBy:sortBy
                                                ascending:ascending
                                            withPredicate:searchTerm
                                                inContext:context];
	[request setPropertiesToFetch:[self propertiesNamed:attributes]];
	
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id) findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)attributes, ...
{
	return [self findFirstWithPredicate:searchTerm
                                  sortedBy:sortBy 
                                 ascending:ascending 
                                 inContext:[NSManagedObjectContext contextForCurrentThread]
                     andRetrieveAttributes:attributes];
}

#pragma mark - Find All By Attribute

+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestAllWhere:attribute isEqualTo:searchValue inContext:context];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue
{
	return [self findByAttribute:attribute
                          withValue:searchValue 
                          inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSPredicate *searchTerm = [NSPredicate predicateWithFormat:@"%K = %@", attribute, searchValue];
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:context];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self findByAttribute:attribute
                          withValue:searchValue
                         andOrderBy:sortTerm 
                          ascending:ascending 
                          inContext:[NSManagedObjectContext contextForCurrentThread]];
}


#pragma mark -
#pragma mark NSFetchedResultsController helpers


#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

+ (NSFetchedResultsController *) fetchController:(NSFetchRequest *)request delegate:(id<NSFetchedResultsControllerDelegate>)delegate useFileCache:(BOOL)useFileCache groupedBy:(NSString *)groupKeyPath inContext:(NSManagedObjectContext *)context
{
    NSString *cacheName = useFileCache ? [NSString stringWithFormat:@"MagicalRecord-Cache-%@", NSStringFromClass([self class])] : nil;
    
	NSFetchedResultsController *controller =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:context
                                          sectionNameKeyPath:groupKeyPath
                                                   cacheName:cacheName];
    controller.delegate = delegate;
    
    return controller;
}

+ (NSFetchedResultsController *) fetchAllWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;
{
    return [self fetchAllWithDelegate:delegate inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchedResultsController *) fetchAllWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self requestAllInContext:context];
    NSFetchedResultsController *controller = [self fetchController:request delegate:delegate useFileCache:NO groupedBy:nil inContext:context];

    [self performFetch:controller];
    return controller;
}

+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm 
                                                ascending:ascending 
                                            withPredicate:searchTerm
                                                inContext:context];
    
    NSFetchedResultsController *controller = [self fetchController:request 
                                                             delegate:delegate
                                                         useFileCache:NO
                                                            groupedBy:group
                                                            inContext:context];
    
    [self performFetch:controller];
    return controller;
}

+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id)delegate
{
	return [self fetchAllGroupedBy:group
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                             delegate:delegate
                            inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
{
    return [self fetchAllGroupedBy:group 
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                             delegate:nil
                            inContext:context];
}

+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending 
{
    return [self fetchAllGroupedBy:group 
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                            inContext:[NSManagedObjectContext contextForCurrentThread]];
}


+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:searchTerm
                                                inContext:context];
    
	NSFetchedResultsController *controller = [self fetchController:request 
                                                             delegate:nil
                                                         useFileCache:NO
                                                            groupedBy:groupingKeyPath
                                                            inContext:[NSManagedObjectContext contextForCurrentThread]];
    
    [self performFetch:controller];
    return controller;
}

+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath;
{
    return [self fetchAllSortedBy:sortTerm
                           ascending:ascending
                       withPredicate:searchTerm
                             groupBy:groupingKeyPath
                           inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
	NSFetchedResultsController *controller = [self fetchAllGroupedBy:groupingKeyPath 
                                                          withPredicate:searchTerm
                                                               sortedBy:sortTerm 
                                                              ascending:ascending
                                                               delegate:delegate
                                                              inContext:context];
	
	[self performFetch:controller];
	return controller;
}

+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate
{
	return [self fetchAllSortedBy:sortTerm 
                           ascending:ascending
                       withPredicate:searchTerm 
                             groupBy:groupingKeyPath 
                            delegate:delegate
                           inContext:[NSManagedObjectContext contextForCurrentThread]];
}

#endif

@end
