//
//  NSManagedObjectContext+MagicalRecord.h
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "MagicalRecord.h"

extern NSString * const kMagicalRecordDidMergeChangesFromiCloudNotification;

@interface NSManagedObjectContext (MagicalRecord)

+ (void) initializeDefaultContextWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;

+ (NSManagedObjectContext *) context NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) contextWithParent:(NSManagedObjectContext *)parentContext NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) newMainQueueContext NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator NS_RETURNS_RETAINED;

+ (void) resetDefaultContext;
+ (NSManagedObjectContext *) rootSavingContext;
+ (NSManagedObjectContext *) defaultContext;

- (NSString *) description;
- (NSString *) parentChain;

@property (nonatomic, copy, setter = setWorkingName:) NSString *workingName;

@end
