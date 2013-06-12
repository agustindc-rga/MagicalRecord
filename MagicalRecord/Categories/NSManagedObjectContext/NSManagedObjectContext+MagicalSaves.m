//
//  NSManagedObjectContext+MagicalSaves.m
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+MagicalSaves.h"
#import "MagicalRecord+ErrorHandling.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "MagicalRecord.h"

@implementation NSManagedObjectContext (MagicalSaves)

- (void)saveOnlySelfWithCompletion:(MRSaveCompletionHandler)completion;
{
    [self saveWithOptions:0 completion:completion];
}

- (void)saveOnlySelfAndWait;
{
    [self saveWithOptions:MRSaveSynchronously completion:nil];
}

- (void) saveToPersistentStoreWithCompletion:(MRSaveCompletionHandler)completion;
{
    [self saveWithOptions:MRSaveParentContexts completion:completion];
}

- (void) saveToPersistentStoreAndWait;
{
    [self saveWithOptions:MRSaveParentContexts | MRSaveSynchronously completion:nil];
}

- (void)saveWithOptions:(MRSaveContextOptions)mask completion:(MRSaveCompletionHandler)completion;
{
    BOOL syncSave           = ((mask & MRSaveSynchronously) == MRSaveSynchronously);
    BOOL saveParentContexts = ((mask & MRSaveParentContexts) == MRSaveParentContexts);

    if (![self hasChanges]) {
        MRLog(@"NO CHANGES IN ** %@ ** CONTEXT - NOT SAVING", [self workingName]);

        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        }
        
        return;
    }

    MRLog(@"→ Saving %@", [self description]);
    MRLog(@"→ Save Parents? %@", @(saveParentContexts));
    MRLog(@"→ Save Synchronously? %@", @(syncSave));

    id saveBlock = ^{
        NSError *error = nil;
        BOOL     saved = NO;

        @try
        {
            saved = [self save:&error];
        }
        @catch(NSException *exception)
        {
            MRLog(@"Unable to perform save: %@", (id)[exception userInfo] ? : (id)[exception reason]);
        }

        @finally
        {
            if (!saved) {
                [MagicalRecord handleErrors:error];

                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(saved, error);
                    });
                }
            } else {
                // If we're the default context, save to disk too (the user expects it to persist)
                BOOL isDefaultContext = (self == [[self class] defaultContext]);
                BOOL shouldSaveParentContext = ((YES == saveParentContexts) || isDefaultContext);
                
                if (shouldSaveParentContext && [self parentContext]) {
                    [[self parentContext] saveWithOptions:mask completion:completion];
                }
                // If we should not save the parent context, or there is not a parent context to save (root context), call the completion block
                else {
                    MRLog(@"→ Finished saving: %@", [self description]);
                    
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(saved, error);
                        });
                    }
                }
            }
        }
    };

    if (YES == syncSave) {
        [self performBlockAndWait:saveBlock];
    } else {
        [self performBlock:saveBlock];
    }
}

#pragma mark - Deprecated methods
// These methods will be removed in MagicalRecord 3.0

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (void)save;
{
    [self saveToPersistentStoreAndWait];
}

- (void)saveWithErrorCallback:(void (^)(NSError *error))errorCallback;
{
    [self saveWithOptions:MRSaveSynchronously|MRSaveParentContexts completion:^(BOOL success, NSError *error) {
        if (!success) {
            if (errorCallback) {
                errorCallback(error);
            }
        }
    }];
}

- (void)saveInBackgroundCompletion:(void (^)(void))completion;
{
    [self saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            if (completion) {
                completion();
            }
        }
    }];
}

- (void)saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback;
{
    [self saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            if (errorCallback) {
                errorCallback(error);
            }
        }
    }];
}

- (void)saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion;
{
    [self saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            if (completion) {
                completion();
            }
        } else {
            if (errorCallback) {
                errorCallback(error);
            }
        }
    }];
}

- (void)saveNestedContexts;
{
    [self saveToPersistentStoreWithCompletion:nil];
}

- (void)saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback;
{
    [self saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            if (errorCallback) {
                errorCallback(error);
            }
        }
    }];
}

- (void)saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion;
{
    [self saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            if (completion) {
                completion();
            }
        } else {
            if (errorCallback) {
                errorCallback(error);
            }
        }
    }];
}

#pragma clang diagnostic pop // ignored "-Wdeprecated-implementations"

@end
