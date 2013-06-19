//
//  NSManagedObjectContextHelperTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContextHelperTests.h"
#import "SingleEntityWithNoRelationships.h";
@implementation NSManagedObjectContextHelperTests

- (void) setUp
{
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void) tearDown
{
    [MagicalRecord cleanUp];
}

- (void) testCanCreateContextForCurrentThead
{
    NSManagedObjectContext *firstContext = [NSManagedObjectContext contextForCurrentThread];
    NSManagedObjectContext *secondContext = [NSManagedObjectContext contextForCurrentThread];
    
    assertThat(firstContext, is(equalTo(secondContext)));
}

- (void) testCanNotifyDefaultContextOnSave
{
    NSManagedObjectContext *testContext = [NSManagedObjectContext contextWithParent:[NSManagedObjectContext defaultContext]];

   assertThat([testContext parentContext], is(equalTo([NSManagedObjectContext defaultContext])));
}

- (void) testThatSavedObjectsHavePermanentIDs
{
    NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
    SingleEntityWithNoRelationships *entity = [SingleEntityWithNoRelationships createInContext:context];
    assertThatBool([[entity objectID] isTemporaryID], equalToBool(YES));
    [context saveOnlySelfAndWait];
    assertThatBool([[entity objectID] isTemporaryID], equalToBool(NO));
}


@end
