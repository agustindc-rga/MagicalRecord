//
//  NSManagedObjectContext+MagicalObserving.h
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (MagicalObserving)

- (void) observeContext:(NSManagedObjectContext *)otherContext;
- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext;
- (void) observeContextOnCurrentThread:(NSManagedObjectContext *)otherContext;
- (void) stopObservingContext:(NSManagedObjectContext *)otherContext;
- (void) stopObservingAllContexts;

- (void) observeiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
- (void) stopObservingiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;

@end
