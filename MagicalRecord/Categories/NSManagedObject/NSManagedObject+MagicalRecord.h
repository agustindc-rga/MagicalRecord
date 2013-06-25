//
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MagicalRecord.h"

#define kMagicalRecordDefaultBatchSize 20

@interface NSManagedObject (MagicalRecord)

+ (NSUInteger) defaultBatchSize;
+ (void) setDefaultBatchSize:(NSUInteger)newBatchSize;

+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request;
+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request;
+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
+ (NSUInteger) countForFetchRequest: (NSFetchRequest *)request;
+ (NSUInteger) countForFetchRequest: (NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

+ (void) performFetch:(NSFetchedResultsController *)controller;

#endif

+ (NSEntityDescription *) entityDescription;
+ (NSEntityDescription *) entityDescriptionInContext:(NSManagedObjectContext *)context;
+ (NSArray *) propertiesNamed:(NSArray *)properties;

+ (id) createEntity;
+ (id) createInContext:(NSManagedObjectContext *)context;
- (BOOL) deleteEntity;
- (BOOL) deleteInContext:(NSManagedObjectContext *)context;

+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate;
+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

+ (BOOL) truncateAll;
+ (BOOL) truncateAllInContext:(NSManagedObjectContext *)context;

+ (NSArray *) ascendingSortDescriptors:(NSArray *)attributesToSortBy;
+ (NSArray *) descendingSortDescriptors:(NSArray *)attributesToSortBy;

- (id) inContext:(NSManagedObjectContext *)otherContext;
- (id) inThreadContext;

@end

