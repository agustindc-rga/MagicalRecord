//
//  NSManagedObjectContext+MagicalObserving.m
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+MagicalObserving.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalThreading.h"
#import "MagicalRecord.h"
#import "MagicalRecord+iCloud.h"
#import <objc/runtime.h>

NSString * const kMagicalRecordDidMergeChangesFromiCloudNotification = @"kMagicalRecordDidMergeChangesFromiCloudNotification";


@implementation NSManagedObjectContext (MagicalObserving)

#pragma mark - Context Observation Helpers

- (void) observeContext:(NSManagedObjectContext *)otherContext
{
    __weak typeof(self) weakSelf = self;
    
    [self observeContext:otherContext withBlock:^(NSNotification *note) {
        [weakSelf mergeChangesFromNotification:note];
    }];
}

- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext
{
    __weak typeof(self) weakSelf = self;
    
    [self observeContext:otherContext withBlock:^(NSNotification *note) {
        [weakSelf mergeChangesOnMainThread:note];
    }];
}

- (void) observeContextOnCurrentThread:(NSManagedObjectContext *)otherContext
{
    __weak typeof(self) weakSelf = self;
    
    [self observeContext:otherContext withBlock:^(NSNotification *note) {
        [weakSelf mergeChangesOnContextThread:note];
    }];
}

- (void)observeContext:(NSManagedObjectContext *)otherContext withBlock:(void (^)(NSNotification *note))block
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    id observer = [notificationCenter addObserverForName:NSManagedObjectContextDidSaveNotification object:otherContext queue:nil usingBlock:block];
    
    [self setContextSaveObserver:observer forContext:otherContext];
}

- (void) stopObservingContext:(NSManagedObjectContext *)otherContext
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:[self contextSaveObserverForContext:otherContext]];

    [self removeContextSaveObserverForContext:otherContext];
}
- (void) stopObservingAllContexts
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  for (id observer in [[self allContextSaveObservers] objectEnumerator])
      [notificationCenter removeObserver:observer];
  
  [[self allContextSaveObservers] removeAllObjects];
}

#pragma mark - Context Observation Properties

static void* kSaveObserverPropertyKey;
static id observerKeyForContext(NSManagedObjectContext* context) {
  return @((uint)context);
}

- (void) setContextSaveObserver:(id)observer forContext:(NSManagedObjectContext*)otherContext
{
  self.allContextSaveObservers[observerKeyForContext(otherContext)] = observer;
}
- (void) removeContextSaveObserverForContext:(NSManagedObjectContext*)otherContext
{
  [self.allContextSaveObservers removeObjectForKey:observerKeyForContext(otherContext)];
}
- (id)contextSaveObserverForContext:(NSManagedObjectContext*)otherContext
{
  return self.allContextSaveObservers[observerKeyForContext(otherContext)];
}

- (NSMutableDictionary*)allContextSaveObservers
{
  NSMutableDictionary *observers = objc_getAssociatedObject(self, &kSaveObserverPropertyKey);
  if (!observers)
  {
    observers = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, &kSaveObserverPropertyKey, observers, OBJC_ASSOCIATION_RETAIN);
  }
  return observers;
}

#pragma mark - Context iCloud Merge Helpers

- (void) mergeChangesFromiCloud:(NSNotification *)notification;
{
    [self performBlock:^{
        
        MRLog(@"Merging changes From iCloud %@context%@", 
              self == [NSManagedObjectContext defaultContext] ? @"*** DEFAULT *** " : @"",
              ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
        
        [self mergeChangesFromContextDidSaveNotification:notification];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter postNotificationName:kMagicalRecordDidMergeChangesFromiCloudNotification
                                          object:self
                                        userInfo:[notification userInfo]];
    }];
}

- (void) mergeChangesFromNotification:(NSNotification *)notification;
{
	MRLog(@"Merging changes to %@context%@", 
          self == [NSManagedObjectContext defaultContext] ? @"*** DEFAULT *** " : @"",
          ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
    
	[self mergeChangesFromContextDidSaveNotification:notification];
}

- (void) mergeChangesOnMainThread:(NSNotification *)notification;
{
	if ([NSThread isMainThread])
	{
		[self mergeChangesFromNotification:notification];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(mergeChangesFromNotification:) withObject:notification waitUntilDone:YES];
	}
}

- (void) mergeChangesOnContextThread:(NSNotification*)notification
{
  NSThread *thread = [self thread];
  if (!thread || thread == [NSThread currentThread])
  {
    [self mergeChangesFromNotification:notification];
  }
  else
  {
    [self performSelector:@selector(mergeChangesFromNotification:) onThread:thread withObject:notification waitUntilDone:NO];
  }
}

- (void) observeiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    if (![MagicalRecord isICloudEnabled]) return;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(mergeChangesFromiCloud:)
                               name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                             object:coordinator];
    
}

- (void) stopObservingiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    if (![MagicalRecord isICloudEnabled]) return;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                object:coordinator];
}

@end
