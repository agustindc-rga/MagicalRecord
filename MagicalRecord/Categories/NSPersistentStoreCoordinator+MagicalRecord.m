//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"

static NSPersistentStoreCoordinator *defaultCoordinator_ = nil;
NSString * const kMagicalRecordPSCDidCompleteiCloudSetupNotification = @"kMagicalRecordPSCDidCompleteiCloudSetupNotification";

@interface NSDictionary (MagicalRecordMerging)

- (NSMutableDictionary*) dictionaryByMergingDictionary:(NSDictionary*)d; 

@end 

@interface MagicalRecord (iCloudPrivate)

+ (void) setICloudEnabled:(BOOL)enabled;

@end

@implementation NSPersistentStoreCoordinator (MagicalRecord)

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
    if (defaultCoordinator_ == nil && [MagicalRecord shouldAutoCreateDefaultPersistentStoreCoordinator])
    {
        [self setDefaultStoreCoordinator:[self newPersistentStoreCoordinator]];
    }
	return defaultCoordinator_;
}

+ (void) setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	defaultCoordinator_ = coordinator;
    
    if (defaultCoordinator_ != nil)
    {
        NSArray *persistentStores = [defaultCoordinator_ persistentStores];
        
        if ([persistentStores count] && [NSPersistentStore defaultPersistentStore] == nil)
        {
            [NSPersistentStore setDefaultPersistentStore:[persistentStores objectAtIndex:0]];
        }
    }
}

- (void) createPathToStoreFileIfNeccessary:(NSURL *)urlForStore
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *pathToStore = [urlForStore URLByDeletingLastPathComponent];
    
    NSError *error = nil;
    BOOL pathWasCreated = [fileManager createDirectoryAtPath:[pathToStore path] withIntermediateDirectories:YES attributes:nil error:&error];

    if (!pathWasCreated) 
    {
        [MagicalRecord handleErrors:error];
    }
}

- (NSPersistentStore *) addSqliteStoreNamed:(id)storeFileName withOptions:(__autoreleasing NSDictionary *)options
{
    NSURL *url = [storeFileName isKindOfClass:[NSURL class]] ? storeFileName : [NSPersistentStore urlForStoreName:storeFileName];
    NSError *error = nil;
    
    [self createPathToStoreFileIfNeccessary:url];
    
    NSPersistentStore *store = [self addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:url
                                                        options:options
                                                          error:&error];
    
    if (!store && [MagicalRecord shouldDeleteStoreOnModelMismatch])
    {
        BOOL isMigrationError = [error code] == NSPersistentStoreIncompatibleVersionHashError || [error code] == NSMigrationMissingSourceModelError;
        if ([[error domain] isEqualToString:NSCocoaErrorDomain] && isMigrationError)
        {
            // Could not open the database, so... kill it! (AND WAL bits)
            NSString *rawURL = [url absoluteString];
            NSURL *shmSidecar = [NSURL URLWithString:[rawURL stringByAppendingString:@"-shm"]];
            NSURL *walSidecar = [NSURL URLWithString:[rawURL stringByAppendingString:@"-wal"]];
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            [[NSFileManager defaultManager] removeItemAtURL:shmSidecar error:nil];
            [[NSFileManager defaultManager] removeItemAtURL:walSidecar error:nil];
            

            MRLog(@"Removed incompatible model version: %@", [url lastPathComponent]);
            
            // Try one more time to create the store
            store = [self addPersistentStoreWithType:NSSQLiteStoreType
                                       configuration:nil
                                                 URL:url
                                             options:options
                                               error:&error];
            if (store)
            {
                // If we successfully added a store, remove the error that was initially created
                error = nil;
            }
        }
    }
    [MagicalRecord handleErrors:error];
  
    return store;
}


#pragma mark - Public Instance Methods

- (NSPersistentStore *) addInMemoryStore
{
    NSError *error = nil;
    NSPersistentStore *store = [self addPersistentStoreWithType:NSInMemoryStoreType
                                                  configuration:nil 
                                                            URL:nil
                                                        options:nil
                                                          error:&error];
    if (!store)
    {
        [MagicalRecord handleErrors:error];
    }
    return store;
}

+ (NSDictionary *) autoMigrationOptions;
{
    // Adding the journalling mode recommended by apple
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             sqliteOptions, NSSQLitePragmasOption,
                             nil];
    return options;
}

- (NSPersistentStore *) addAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
{
    NSDictionary *options = [[self class] autoMigrationOptions];
    return [self addSqliteStoreNamed:storeFileName withOptions:options];
}


#pragma mark - Public Class Methods


+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
    NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [coordinator addAutoMigratingSqliteStoreNamed:storeFileName];

    return coordinator;
}

+ (NSPersistentStoreCoordinator *) coordinatorWithInMemoryStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    [coordinator addInMemoryStore];

    return coordinator;
}

+ (NSPersistentStoreCoordinator *) newPersistentStoreCoordinator
{
	NSPersistentStoreCoordinator *coordinator = [self coordinatorWithSqliteStoreNamed:[MagicalRecord defaultStoreName]];

    return coordinator;
}

- (void) addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
{
    [self addiCloudContainerID:containerID 
                   contentNameKey:contentNameKey 
                  localStoreNamed:localStoreName
          cloudStorePathComponent:subPathComponent
                       completion:nil];
}

- (void) addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL *cloudURL = [NSPersistentStore cloudURLForUbiqutiousContainer:containerID];
        if (subPathComponent) 
        {
            cloudURL = [cloudURL URLByAppendingPathComponent:subPathComponent];
        }

        [MagicalRecord setICloudEnabled:cloudURL != nil];
        
        NSDictionary *options = [[self class] autoMigrationOptions];
        if (cloudURL)   //iCloud is available
        {
            NSDictionary *iCloudOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                           contentNameKey, NSPersistentStoreUbiquitousContentNameKey,
                                           cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
            options = [options dictionaryByMergingDictionary:iCloudOptions];
        }
        else 
        {
            MRLog(@"iCloud is not enabled");
        }
        
        [self lock];
        [self addSqliteStoreNamed:localStoreName withOptions:options];
        [self unlock];

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([NSPersistentStore defaultPersistentStore] == nil)
            {
                [NSPersistentStore setDefaultPersistentStore:[[self persistentStores] objectAtIndex:0]];
            }
            if (completionBlock)
            {
                completionBlock();
            }
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:kMagicalRecordPSCDidCompleteiCloudSetupNotification object:nil];
        });
    });   
}

+ (NSPersistentStoreCoordinator *) coordinatorWithiCloudContainerID:(NSString *)containerID 
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreNamed:(NSString *)localStoreName
                                               cloudStorePathComponent:(NSString *)subPathComponent;
{
    return [self coordinatorWithiCloudContainerID:containerID 
                                      contentNameKey:contentNameKey
                                     localStoreNamed:localStoreName
                             cloudStorePathComponent:subPathComponent
                                          completion:nil];
}

+ (NSPersistentStoreCoordinator *) coordinatorWithiCloudContainerID:(NSString *)containerID 
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreNamed:(NSString *)localStoreName
                                               cloudStorePathComponent:(NSString *)subPathComponent
                                                            completion:(void(^)(void))completionHandler;
{
    NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc addiCloudContainerID:containerID 
                  contentNameKey:contentNameKey
                 localStoreNamed:localStoreName
         cloudStorePathComponent:subPathComponent
                      completion:completionHandler];
    
    return psc;
}

+ (NSPersistentStoreCoordinator *) coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore;
{
    NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc addSqliteStoreNamed:[persistentStore URL] withOptions:nil];

    return psc;
}

+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options
{
    NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc addSqliteStoreNamed:storeFileName withOptions:options];
    return psc;
}

+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreNamed:(NSString *)storeFileName
{
	return [self coordinatorWithSqliteStoreNamed:storeFileName withOptions:nil];
}

@end


@implementation NSDictionary (Merging) 

- (NSMutableDictionary *) dictionaryByMergingDictionary:(NSDictionary *)d;
{
    NSMutableDictionary *mutDict = [self mutableCopy];
    [mutDict addEntriesFromDictionary:d];
    return mutDict; 
} 

@end 
