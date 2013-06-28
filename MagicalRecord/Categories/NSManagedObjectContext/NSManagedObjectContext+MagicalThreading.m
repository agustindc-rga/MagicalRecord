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
#import "NSManagedObjectContext+MagicalObserving.h"
#import <objc/runtime.h>

static NSString const * kMagicalRecordManagedObjectContextKey = @"MagicalRecord_NSManagedObjectContextForThreadKey";

@implementation NSManagedObjectContext (MagicalThreading)

+ (void)resetContextForCurrentThread
{
    [[self contextForCurrentThread] reset];
}

+ (NSManagedObjectContext *) contextForCurrentThread;
{
  NSManagedObjectContext *defaultContext = [self defaultContext];
  
	if ([NSThread isMainThread])
	{
		return defaultContext;
	}
	else
	{
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextKey];
		if (threadContext == nil || threadContext.parentContext != defaultContext)
		{
      [threadContext stopObservingContext:threadContext.parentContext];
			threadContext = [self contextWithParent:defaultContext];
      [threadContext setThread:[NSThread currentThread]];
      [threadContext observeContext:defaultContext];
      
			[threadDict setObject:threadContext forKey:kMagicalRecordManagedObjectContextKey];
		}
		return threadContext;
	}
}

#pragma mark - Thread Reference

static void* kThreadPropertyKey;

- (void)setThread:(NSThread*)thread
{
  objc_setAssociatedObject(self, &kThreadPropertyKey, thread, OBJC_ASSOCIATION_ASSIGN);
}
- (NSThread*)thread
{
  return objc_getAssociatedObject(self, &kThreadPropertyKey);
}

@end
