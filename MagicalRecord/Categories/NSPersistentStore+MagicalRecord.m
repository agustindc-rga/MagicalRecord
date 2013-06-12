//
//  NSPersistentStore+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

//#import "NSPersistentStore+MagicalRecord.h"
#import "CoreData+MagicalRecord.h"

NSString * const kMagicalRecordDefaultStoreFileName = @"CoreDataStore.sqlite";

static NSPersistentStore *defaultPersistentStore_ = nil;


@implementation NSPersistentStore (MagicalRecord)

+ (NSPersistentStore *) defaultPersistentStore
{
	return defaultPersistentStore_;
}

+ (void) setDefaultPersistentStore:(NSPersistentStore *) store
{
	defaultPersistentStore_ = store;
}

+ (NSString *) directory:(int) type
{    
    return [NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationDocumentsDirectory 
{
	return [self directory:NSDocumentDirectory];
}

+ (NSString *)applicationStorageDirectory
{
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    return [[self directory:NSApplicationSupportDirectory] stringByAppendingPathComponent:applicationName];
}

+ (NSURL *) urlForStoreName:(NSString *)storeFileName
{
	NSArray *paths = [NSArray arrayWithObjects:[self applicationDocumentsDirectory], [self applicationStorageDirectory], nil];
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    for (NSString *path in paths) 
    {
        NSString *filepath = [path stringByAppendingPathComponent:storeFileName];
        if ([fm fileExistsAtPath:filepath])
        {
            return [NSURL fileURLWithPath:filepath];
        }
    }

    //set default url
    return [NSURL fileURLWithPath:[[self applicationStorageDirectory] stringByAppendingPathComponent:storeFileName]];
}

+ (NSURL *) cloudURLForUbiqutiousContainer:(NSString *)bucketName;
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *cloudURL = nil;
    if ([fileManager respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)])
    {
        cloudURL = [fileManager URLForUbiquityContainerIdentifier:bucketName];
    }

    return cloudURL;
}

+ (NSURL *) defaultLocalStoreUrl
{
    return [self urlForStoreName:kMagicalRecordDefaultStoreFileName];
}

@end
