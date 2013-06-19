//
//  MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"

@interface MagicalRecord (Internal)

+ (void) cleanUpStack;
+ (void) cleanUpErrorHanding;

@end

@interface NSManagedObjectContext (MagicalRecordInternal)

+ (void) cleanUp;

@end


@implementation MagicalRecord

+ (void) cleanUp
{
    [self cleanUpErrorHanding];
    [self cleanUpStack];
}

+ (void) cleanUpStack;
{
	[NSManagedObjectContext cleanUp];
	[NSManagedObjectModel setDefaultManagedObjectModel:nil];
	[NSPersistentStoreCoordinator setDefaultStoreCoordinator:nil];
	[NSPersistentStore setDefaultPersistentStore:nil];
}

+ (NSString *) currentStack
{
    NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];

    [status appendFormat:@"Model:           %@\n", [[NSManagedObjectModel defaultManagedObjectModel] entityVersionHashesByName]];
    [status appendFormat:@"Coordinator:     %@\n", [NSPersistentStoreCoordinator defaultStoreCoordinator]];
    [status appendFormat:@"Store:           %@\n", [NSPersistentStore defaultPersistentStore]];
    [status appendFormat:@"Default Context: %@\n", [[NSManagedObjectContext defaultContext] description]];
    [status appendFormat:@"Context Chain:   \n%@\n", [[NSManagedObjectContext defaultContext] parentChain]];

    return status;
}

+ (void) setDefaultModelNamed:(NSString *)modelName;
{
    NSManagedObjectModel *model = [NSManagedObjectModel managedObjectModelNamed:modelName];
    [NSManagedObjectModel setDefaultManagedObjectModel:model];
}

+ (void) setDefaultModelFromClass:(Class)klass;
{
    NSBundle *bundle = [NSBundle bundleForClass:klass];
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
    [NSManagedObjectModel setDefaultManagedObjectModel:model];
}

+ (NSString *) defaultStoreName;
{
    NSString *defaultName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
    if (defaultName == nil)
    {
        defaultName = kMagicalRecordDefaultStoreFileName;
    }
    if (![defaultName hasSuffix:@"sqlite"]) 
    {
        defaultName = [defaultName stringByAppendingPathExtension:@"sqlite"];
    }

    return defaultName;
}


#pragma mark - initialize

+ (void) initialize;
{
    if (self == [MagicalRecord class]) 
    {
        [self setShouldAutoCreateManagedObjectModel:YES];
        [self setShouldAutoCreateDefaultPersistentStoreCoordinator:NO];
#ifdef DEBUG
        [self setShouldDeleteStoreOnModelMismatch:YES];
#else
        [self setShouldDeleteStoreOnModelMismatch:NO];
#endif
    }
}

@end


