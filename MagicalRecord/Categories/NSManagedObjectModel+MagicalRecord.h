//
//  NSManagedObjectModel+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MagicalRecord.h"


@interface NSManagedObjectModel (MagicalRecord)

+ (NSManagedObjectModel *) defaultManagedObjectModel;

+ (void) setDefaultManagedObjectModel:(NSManagedObjectModel *)newDefaultModel;

+ (NSManagedObjectModel *) mergedObjectModelFromMainBundle;
+ (NSManagedObjectModel *) newManagedObjectModelNamed:(NSString *)modelFileName NS_RETURNS_RETAINED;
+ (NSManagedObjectModel *) managedObjectModelNamed:(NSString *)modelFileName;
+ (NSManagedObjectModel *) newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName NS_RETURNS_RETAINED;

@end
