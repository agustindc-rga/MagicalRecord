//
//  NSManagedObjectContext+MagicalSaves.h
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NS_OPTIONS(NSUInteger, MRSaveContextOptions) {
    MRSaveParentContexts = 1,   ///< When saving, continue saving parent contexts until the changes are present in the persistent store
    MRSaveSynchronously = 2     ///< Peform saves synchronously, blocking execution on the current thread until the save is complete
};

typedef void (^MRSaveCompletionHandler)(BOOL success, NSError *error);

@interface NSManagedObjectContext (MagicalSaves)

/// \brief      Asynchronously save changes in the current context and it's parent
/// \param       completion  Completion block that is called after the save has completed. The block is passed a success state as a `BOOL` and an `NSError` instance if an error occurs. Always called on the main queue.
/// \discussion Executes a save on the current context's dispatch queue asynchronously. This method only saves the current context, and the parent of the current context if one is set. The completion block will always be called on the main queue.
- (void) saveOnlySelfWithCompletion:(MRSaveCompletionHandler)completion;

/// \brief      Asynchronously save changes in the current context all the way back to the persistent store
/// \param       completion  Completion block that is called after the save has completed. The block is passed a success state as a `BOOL` and an `NSError` instance if an error occurs. Always called on the main queue.
/// \discussion Executes asynchronous saves on the current context, and any ancestors, until the changes have been persisted to the assigned persistent store. The completion block will always be called on the main queue.
- (void) saveToPersistentStoreWithCompletion:(MRSaveCompletionHandler)completion;

/// \brief      Synchronously save changes in the current context and it's parent
/// \discussion Executes a save on the current context's dispatch queue. This method only saves the current context, and the parent of the current context if one is set. The method will not return until the save is complete.
- (void) saveOnlySelfAndWait;

/// \brief      Synchronously save changes in the current context and it's parent
/// \param      error  A pointer to an NSError object. You do not need to create an NSError object.
/// \return     YES if the save succeeds, otherwise NO.
/// \discussion Executes a save on the current context's dispatch queue. This method only saves the current context, and the parent of the current context if one is set. The method will not return until the save is complete.
- (BOOL) saveOnlySelfAndWait:(NSError**)error;

/// \brief      Synchronously save changes in the current context all the way back to the persistent store
/// \discussion Executes saves on the current context, and any ancestors, until the changes have been persisted to the assigned persistent store. The method will not return until the save is complete.
- (void) saveToPersistentStoreAndWait;

/// \brief      Synchronously save changes in the current context all the way back to the persistent store
/// \param      error  A pointer to an NSError object. You do not need to create an NSError object.
/// \return     YES if the save succeeds, otherwise NO.
/// \discussion Executes saves on the current context, and any ancestors, until the changes have been persisted to the assigned persistent store. The method will not return until the save is complete.
- (BOOL) saveToPersistentStoreAndWait:(NSError**)error;

/// \brief       Save the current context with options
/// \param       mask        bitmasked options for the save process
/// \param       completion  Completion block that is called after the save has completed. The block is passed a success state as a `BOOL` and an `NSError` instance if an error occurs. Called on the main queue for asynchronous saves, otherwise called in the current queue.
/// \discussion  All other save methods are conveniences to this method.
 - (void) saveWithOptions:(MRSaveContextOptions)mask completion:(MRSaveCompletionHandler)completion;


/* DEPRECATION NOTICE:
 * The following methods are deprecated, but remain in place for backwards compatibility until the next major version (3.x)
 */

/// \brief      Synchronously save changes in the current context all the way back to the persistent store
/// \discussion Replaced by \saveToPersistentStoreAndWait
/// \deprecated
- (void) save __attribute__((deprecated));

/// \brief      Synchronously save changes in the current context all the way back to the persistent store
/// \param      errorCallback Block that is called if an error is encountered while saving. Always called on the main thread.
/// \deprecated
- (void) saveWithErrorCallback:(void(^)(NSError *error))errorCallback __attribute__((deprecated));

/// \brief      Asynchronously save changes in the current context and it's parent
/// \param      completion  Completion block that is called after the save has completed. Always called on the main queue.
/// \deprecated
- (void) saveInBackgroundCompletion:(void (^)(void))completion __attribute__((deprecated));

/// \brief      Asynchronously save changes in the current context and it's parent
/// \param      errorCallback Block that is called if an error is encountered while saving. Always called on the main thread.
/// \deprecated
- (void) saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback __attribute__((deprecated));

/// \brief      Asynchronously save changes in the current context and it's parent
/// \param      errorCallback Block that is called if an error is encountered while saving. Always called on the main thread.
/// \param      completion  Completion block that is called after the save has completed. Always called on the main queue.
/// \deprecated
- (void) saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion __attribute__((deprecated));

/// \brief      Asynchronously save changes in the current context all the way back to the persistent store
/// \discussion Replaced by \saveToPersistentStoreWithCompletion:
/// \deprecated
- (void) saveNestedContexts __attribute__((deprecated));

/// \brief      Asynchronously save changes in the current context all the way back to the persistent store
/// \param      errorCallback Block that is called if an error is encountered while saving. Always called on the main thread.
/// \discussion Replaced by \saveToPersistentStoreWithCompletion:
/// \deprecated
- (void) saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback __attribute__((deprecated));

/// \brief      Asynchronously save changes in the current context all the way back to the persistent store
/// \param      errorCallback Block that is called if an error is encountered while saving. Always called on the main thread.
/// \param      completion  Completion block that is called after the save has completed. Always called on the main queue.
/// \discussion Replaced by \saveToPersistentStoreWithCompletion:
/// \deprecated
- (void) saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion __attribute__((deprecated));

@end
