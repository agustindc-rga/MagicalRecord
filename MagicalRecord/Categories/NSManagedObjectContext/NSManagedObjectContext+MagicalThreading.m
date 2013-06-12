//
//  NSManagedObjectContext+MagicalThreading.m
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+MagicalThreading.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"

static NSString const * kMagicalRecordManagedObjectContextKey = @"MagicalRecord_NSManagedObjectContextForThreadKey";

@implementation NSManagedObjectContext (MagicalThreading)

+ (void)resetContextForCurrentThread
{
    [[NSManagedObjectContext contextForCurrentThread] reset];
}

+ (NSManagedObjectContext *) contextForCurrentThread;
{
	if ([NSThread isMainThread])
	{
		return [self defaultContext];
	}
	else
	{
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextKey];
		if (threadContext == nil)
		{
			threadContext = [self contextWithParent:[NSManagedObjectContext defaultContext]];
			[threadDict setObject:threadContext forKey:kMagicalRecordManagedObjectContextKey];
		}
		return threadContext;
	}
}

@end
