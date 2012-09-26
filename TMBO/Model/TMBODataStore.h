//
//  TMBODataStore.h
//  TMBO
//
//  Created by Scott Perry on 09/25/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `TMBODataStore` offers a simple programmatic interface to reading and writing data on TMBO.
 
 ## Local caching
 
 The `TMBODataStore` singleton caches relevant data locally for fast access between application launches. This data is pruned automatically to maintain a low impact on local nonvolatile memory.
 
 ## Asynchronous fetching
 
 Data is fetched from the server asynchronously, and methods of this class follow a simple naming convention to indicate their functionality:
 
 - Methods beginning in `cached` fetch their data from the local Core Data model and return it synchronously. Their results may be empty/nil.
 - Methods beginning in `set` affect the local data state immediately, and spawn an asynchronous operation to push the change to the server.
 - All other methods take a completion block that is passed the result and an NSError as parameters.
 
 ## Development notes
 
 When DEBUG is defined, the model will fail fast and hard wherever possible. If a data getter/setter method is called and there is no token, an exception will be thrown. If `-updateUploadsWithType:inRange:completion:` is called with a range of uploads that is not within the set of uploads cached locally, an exception will be thrown. 
*/

typedef enum : NSUInteger {
    kTMBOTypeImage  = 0x1,
    kTMBOTypeTopic  = 0x2,
    kTMBOTypeAudio  = 0x4,
    kTMBOTypeAvatar = 0x8,
    kTMBOTypeFile   = kTMBOTypeImage | kTMBOTypeAudio | kTMBOTypeAvatar,
    kTMBOTypeAny    = kTMBOTypeImage | kTMBOTypeTopic | kTMBOTypeAudio | kTMBOTypeAvatar
} kTMBOType;

typedef struct {
    NSUInteger first;
    NSUInteger last;
} TMBORange;

@interface TMBODataStore : NSObject

///----------------------
/// @name Class Singleton
///----------------------

/**
 TMBODataStore is a singleton class. All access to the class' instance method should be done using the value returned from `[TMBODataStore sharedStore]`
 
 @return The shared store object. This is created automatically as needed.
 */

+ (TMBODataStore *)sharedStore;

///----------------------------
/// @name Accessing Upload Data
///----------------------------

/**
 Fetches locally-cached upload data.
 
 If possible, this method will initiate traffic to update the objects returned with fresh data from the server.
 
 @param type The type of upload to return
 @param near The upload id to center the request near.
 
 @return An array of `Upload` objects, up to 50 since `near` and up to 100 before `near`.
 */
- (NSArray *)cachedUploadsWithType:(kTMBOType)type near:(NSUInteger)near;

/**
 Fetches upload data after a specified upload, from the server if required.
 
 If the local cache contains objects that can fulfill this method, the completion block is called synchronously with the local data and this method will initiate traffic to update the objects returned with fresh data from the server.
 
 @param type The type of upload to return
 @param since The minimum uploadid of the returned result set, inclusive.
 @param block A block that takes two arguments: a result array containing zero or more Upload objects and an `NSError` indicating the success of the operation. If the operation was successful, the `NSError` parameter will be `nil`. If the operation was successful and the result array is empty or contains only the object for `since`, then the server does not have any uploads newer than `since`.
 */
- (void)uploadsWithType:(kTMBOType)type since:(NSUInteger)since completion:(void (^)(NSArray *, NSError *))block;

/**
 Fetches upload data before a specified upload, from the server if required.
 
 If the local cache contains objects that can fulfill this method, the completion block is called synchronously with the local data and this method will initiate traffic to update the objects returned with fresh data from the server.
 
 @param type The type of upload to return
 @param before The maximum uploadid of the returned result set, inclusive.
 @param block A block that takes two arguments: a result array containing zero or more Upload objects and an `NSError` indicating the success of the operation. If the operation was successful, the `NSError` parameter will be `nil`. If the operation was successful and the result array is empty or contains only the object for `before`, then the server does not have any uploads older than `before`.
 */
- (void)uploadsWithType:(kTMBOType)type before:(NSUInteger)before completion:(void (^)(NSArray *, NSError *))block;

/**
 Fetches the most recent 50 uploads from the server.
 
 @param type The type of upload to return
 @param block A block that takes two arguments: a result array containing 50 Upload objects or set to nil and an `NSError` indicating the success of the operation. If the operation was successful, the `NSError` parameter will be `nil`.
 */
- (void)latestUploadsWithType:(kTMBOType)type completion:(void (^)(NSArray *, NSError *))block;

/**
 Synchronizes upload data with the server.
 
 @param type The type of upload to update
 @param range The range of uploads to update, inclusive
 @param block A block with no arguments that is called when all updates inside the range have been processed.
 */
- (void)updateUploadsWithType:(kTMBOType)type inRange:(TMBORange)range completion:(void (^)(void))block;

///---------------------------------
/// @name Pickuplink Property Access
///---------------------------------

/**
 Gets the pickuplink for the given upload type from the server.
 
 @discussion This method may cache its value for a period of time to avoid unnecessary network traffic. In cases where a memoized value is returned, the callback block is called synchronously.
 
 @warning An exception will be raised if type is a composite value.
 
 @param type The type of pickuplink to fetch. May only be one of kTMBOTypeImage, kTMBOTypeTopic, kTMBOTypeAudio, or kTMBOTypeAvatar.
 @param block A block with two arguments: a result integer and an `NSError`.
 */
- (void)latestIDForType:(kTMBOType)type completion:(void (^)(NSUInteger, NSError *))block;

// TODO: support setting the pickuplink. the site API should 1) return the current pickuplink as a response and 2) only update the pickuplink if the argument is larger than the incumbent data.

///---------------------
/// @name Authentication
///---------------------

/**
 Attempts to create and acquire an authentication token from the server.
 
 This should only be called by the login view controller after it has been invoked by the app delegate after an API authentication failure. The token is saved by the model.
 
 @param username The member's username
 @param password The member's password
 @param block A block with one argument, an `NSError` indicating the success of the operation. If nil, login was successful and the model is active.
 */
- (void)authenticateUsername:(NSString *)username password:(NSString *)password completion:(void (^)(NSError *))block;

@end
