
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"

static NSUInteger defaultBatchSize = kMagicalRecordDefaultBatchSize;


@implementation NSManagedObject (MagicalRecord)

+ (void) setDefaultBatchSize:(NSUInteger)newBatchSize
{
	@synchronized(self)
	{
		defaultBatchSize = newBatchSize;
	}
}

+ (NSUInteger) defaultBatchSize
{
	return defaultBatchSize;
}

+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
    __block NSArray *results = nil;
    [context performBlockAndWait:^{

        NSError *error = nil;
        
        results = [context executeFetchRequest:request error:&error];
        
        if (results == nil) 
        {
            [MagicalRecord handleErrors:error];
        }

    }];
	return results;	
}

+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request
{
	return [self executeFetchRequest:request inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	[request setFetchLimit:1];
	
	NSArray *results = [self executeFetchRequest:request inContext:context];
	if ([results count] == 0)
	{
		return nil;
	}
	return [results objectAtIndex:0];
}

+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request
{
	return [self executeFetchRequestAndReturnFirstObject:request inContext:[NSManagedObjectContext contextForCurrentThread]];
}


+ (NSUInteger) countForFetchRequest: (NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
  __block NSUInteger count = NSNotFound;
  [context performBlockAndWait:^{
    
    NSError *error = nil;
    
    count = [context countForFetchRequest:request error:&error];
    
    if (count == NSNotFound)
    {
      [MagicalRecord handleErrors:error];
    }
    
  }];
	return count;
}

+ (NSUInteger) countForFetchRequest: (NSFetchRequest *)request
{
  return [self countForFetchRequest:request inContext:[NSManagedObjectContext contextForCurrentThread]];
}

#if TARGET_OS_IPHONE

+ (void) performFetch:(NSFetchedResultsController *)controller
{
	NSError *error = nil;
	if (![controller performFetch:&error])
	{
		[MagicalRecord handleErrors:error];
	}
}

#endif

+ (NSString *) entityName
{
    return NSStringFromClass(self);
}

+ (NSEntityDescription *) entityDescriptionInContext:(NSManagedObjectContext *)context
{
    if ([self respondsToSelector:@selector(entityInManagedObjectContext:)]) 
    {
        NSEntityDescription *entity = [self performSelector:@selector(entityInManagedObjectContext:) withObject:context];
        return entity;
    }
    else
    {
        NSString *entityName = [self entityName];
        return [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    }
}

+ (NSEntityDescription *) entityDescription
{
	return [self entityDescriptionInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) propertiesNamed:(NSArray *)properties
{
	NSEntityDescription *description = [self entityDescription];
	NSMutableArray *propertiesWanted = [NSMutableArray array];
	
	if (properties)
	{
		NSDictionary *propDict = [description propertiesByName];
		
		for (NSString *propertyName in properties)
		{
			NSPropertyDescription *property = [propDict objectForKey:propertyName];
			if (property)
			{
				[propertiesWanted addObject:property];
			}
			else
			{
				MRLog(@"Property '%@' not found in %lx properties for %@", propertyName, (unsigned long)[propDict count], NSStringFromClass(self));
			}
		}
	}
	return propertiesWanted;
}

+ (NSArray *) sortAscending:(BOOL)ascending attributes:(NSArray *)attributesToSortBy
{
	NSMutableArray *attributes = [NSMutableArray array];
    
    for (NSString *attributeName in attributesToSortBy) 
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:attributeName ascending:ascending];
        [attributes addObject:sortDescriptor];
    }
    
	return attributes;
}

+ (NSArray *) ascendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self sortAscending:YES attributes:attributesToSortBy];
}

+ (NSArray *) descendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self sortAscending:NO attributes:attributesToSortBy];
}

#pragma mark -

+ (id) createInContext:(NSManagedObjectContext *)context
{
    if ([self respondsToSelector:@selector(insertInManagedObjectContext:)]) 
    {
        id entity = [self performSelector:@selector(insertInManagedObjectContext:) withObject:context];
        return entity;
    }
    else
    {
        return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
    }
}

+ (id) createEntity
{	
	NSManagedObject *newEntity = [self createInContext:[NSManagedObjectContext contextForCurrentThread]];

	return newEntity;
}

- (BOOL) deleteInContext:(NSManagedObjectContext *)context
{
	[context deleteObject:self];
	return YES;
}

- (BOOL) deleteEntity
{
	[self deleteInContext:[self managedObjectContext]];
	return YES;
}

+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestAllWithPredicate:predicate inContext:context];
    [request setReturnsObjectsAsFaults:YES];
	[request setIncludesPropertyValues:NO];
    
	NSArray *objectsToTruncate = [self executeFetchRequest:request inContext:context];
    
	for (id objectToTruncate in objectsToTruncate) 
    {
		[objectToTruncate deleteInContext:context];
	}
    
	return YES;
}

+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate
{
    return [self deleteAllMatchingPredicate:predicate inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (BOOL) truncateAllInContext:(NSManagedObjectContext *)context
{
    NSArray *allEntities = [self findAllInContext:context];
    for (NSManagedObject *obj in allEntities)
    {
        [obj deleteInContext:context];
    }
    return YES;
}

+ (BOOL) truncateAll
{
    [self truncateAllInContext:[NSManagedObjectContext contextForCurrentThread]];
    return YES;
}

- (id) inContext:(NSManagedObjectContext *)otherContext
{
    NSError *error = nil;
    NSManagedObject *inContext = [otherContext existingObjectWithID:[self objectID] error:&error];
    [MagicalRecord handleErrors:error];
    
    return inContext;
}

- (id) inThreadContext
{
    NSManagedObject *weakSelf = self;
    return [weakSelf inContext:[NSManagedObjectContext contextForCurrentThread]];
}

@end
