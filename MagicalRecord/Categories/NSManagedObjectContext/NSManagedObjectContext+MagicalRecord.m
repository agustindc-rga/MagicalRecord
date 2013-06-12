//
//  NSManagedObjectContext+MagicalRecord.m
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import <objc/runtime.h>

static NSManagedObjectContext *rootSavingContext = nil;
static NSManagedObjectContext *defaultManagedObjectContext_ = nil;
static id iCloudSetupNotificationObserver = nil;

static NSString * const kMagicalRecordNSManagedObjectContextWorkingName = @"kNSManagedObjectContextWorkingName";

@interface NSManagedObjectContext (MagicalRecordInternal)

- (void) mergeChangesFromNotification:(NSNotification *)notification;
- (void) mergeChangesOnMainThread:(NSNotification *)notification;
+ (void) setDefaultContext:(NSManagedObjectContext *)moc;
+ (void) setRootSavingContext:(NSManagedObjectContext *)context;

@end


@implementation NSManagedObjectContext (MagicalRecord)

+ (void) cleanUp;
{
    [self setDefaultContext:nil];
    [self setRootSavingContext:nil];
}

- (NSString *) description;
{
    NSString *contextLabel = [NSString stringWithFormat:@"*** %@ ***", [self workingName]];
    NSString *onMainThread = [NSThread isMainThread] ? @"*** MAIN THREAD ***" : @"*** BACKGROUND THREAD ***";

    return [NSString stringWithFormat:@"<%@ (%p): %@> on %@", NSStringFromClass([self class]), self, contextLabel, onMainThread];
}

- (NSString *) parentChain;
{
    NSMutableString *familyTree = [@"\n" mutableCopy];
    NSManagedObjectContext *currentContext = self;
    do
    {
        [familyTree appendFormat:@"- %@ (%p) %@\n", [currentContext workingName], currentContext, (currentContext == self ? @"(*)" : @"")];
    }
    while ((currentContext = [currentContext parentContext]));

    return [NSString stringWithString:familyTree];
}

+ (NSManagedObjectContext *) defaultContext
{
	@synchronized (self)
	{
        NSAssert(defaultManagedObjectContext_ != nil, @"Default Context is nil! Did you forget to initialize the Core Data Stack?");
        return defaultManagedObjectContext_;
	}
}

+ (void) setDefaultContext:(NSManagedObjectContext *)moc
{
    if (defaultManagedObjectContext_)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:defaultManagedObjectContext_];
    }
    
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
    if (iCloudSetupNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:iCloudSetupNotificationObserver];
        iCloudSetupNotificationObserver = nil;
    }
    
    if ([MagicalRecord isICloudEnabled]) 
    {
        [defaultManagedObjectContext_ stopObservingiCloudChangesInCoordinator:coordinator];
    }

    defaultManagedObjectContext_ = moc;
    [defaultManagedObjectContext_ setWorkingName:@"DEFAULT"];
    
    if ((defaultManagedObjectContext_ != nil) && ([self rootSavingContext] != nil)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rootContextChanged:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:[self rootSavingContext]];
    }
    
    [moc obtainPermanentIDsBeforeSaving];
    if ([MagicalRecord isICloudEnabled])
    {
        [defaultManagedObjectContext_ observeiCloudChangesInCoordinator:coordinator];
    }
    else
    {
        // If icloud is NOT enabled at the time of this method being called, listen for it to be setup later, and THEN set up observing cloud changes
        iCloudSetupNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMagicalRecordPSCDidCompleteiCloudSetupNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *note) {
                                                                           [[NSManagedObjectContext defaultContext] observeiCloudChangesInCoordinator:coordinator];
                                                                       }];        
    }
    MRLog(@"Set Default Context: %@", defaultManagedObjectContext_);
}

+ (void)rootContextChanged:(NSNotification *)notification {
    if ([NSThread isMainThread] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rootContextChanged:notification];
        });
        
        return;
    }
    
    [[self defaultContext] mergeChangesFromContextDidSaveNotification:notification];
}

+ (NSManagedObjectContext *) rootSavingContext;
{
    return rootSavingContext;
}

+ (void) setRootSavingContext:(NSManagedObjectContext *)context;
{
    if (rootSavingContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:rootSavingContext];
    }
    
    rootSavingContext = context;
    [context obtainPermanentIDsBeforeSaving];
    [rootSavingContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [rootSavingContext setWorkingName:@"BACKGROUND SAVING (ROOT)"];
    MRLog(@"Set Root Saving Context: %@", rootSavingContext);
}

+ (void) initializeDefaultContextWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    if (defaultManagedObjectContext_ == nil)
    {
        NSManagedObjectContext *rootContext = [self contextWithStoreCoordinator:coordinator];
        [self setRootSavingContext:rootContext];
        
        NSManagedObjectContext *defaultContext = [self newMainQueueContext];
        [self setDefaultContext:defaultContext];
        
        [defaultContext setParentContext:rootContext];
    }
}

+ (void) resetDefaultContext
{
    void (^resetBlock)(void) = ^{
        [[NSManagedObjectContext defaultContext] reset];
    };
    
    dispatch_async(dispatch_get_main_queue(), resetBlock);
}

+ (NSManagedObjectContext *) contextWithoutParent;
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    return context;
}

+ (NSManagedObjectContext *) context;
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setParentContext:[self defaultContext]];
    return context;
}

+ (NSManagedObjectContext *) contextWithParent:(NSManagedObjectContext *)parentContext;
{
    NSManagedObjectContext *context = [self contextWithoutParent];
    [context setParentContext:parentContext];
    [context obtainPermanentIDsBeforeSaving];
    return context;
}

+ (NSManagedObjectContext *) newMainQueueContext;
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    MRLog(@"Created Main Queue Context: %@", context);
    return context;    
}

+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
	NSManagedObjectContext *context = nil;
    if (coordinator != nil)
	{
        context = [self contextWithoutParent];
        [context performBlockAndWait:^{
            [context setPersistentStoreCoordinator:coordinator];
        }];
        
        MRLog(@"-> Created Context %@", [context workingName]);
    }
    return context;
}

- (void) obtainPermanentIDsBeforeSaving;
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextWillSave:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self];
    
    
}

- (void) contextWillSave:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *insertedObjects = [context insertedObjects];

    if ([insertedObjects count])
    {
        MRLog(@"Context %@ is about to save. Obtaining permanent IDs for new %lu inserted objects", [context workingName], (unsigned long)[insertedObjects count]);
        NSError *error = nil;
        BOOL success = [context obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
        if (!success)
        {
            [MagicalRecord handleErrors:error];
        }
    }
}

- (void) setWorkingName:(NSString *)workingName;
{
    [[self userInfo] setObject:workingName forKey:kMagicalRecordNSManagedObjectContextWorkingName];
}

- (NSString *) workingName;
{
    NSString *workingName = [[self userInfo] objectForKey:kMagicalRecordNSManagedObjectContextWorkingName];
    if (nil == workingName)
    {
        workingName = @"UNNAMED";
    }
    return workingName;
}


@end
