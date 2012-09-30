//
//  TMBODataStore.h
//  TMBO
//
//  Created by Scott Perry on 09/25/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
 
 Note that the methods taking completion blocks will call them on any thread. If you need to interact with UI in your completion block, you should nest a `dispatch_async()` within it, targeting the main thread (`dispatch_get_main_queue()`)
 
 ## Development notes
 
 When DEBUG is defined, the model will fail fast and hard wherever possible. If a data getter/setter method is called and there is no token, an exception will be thrown. If `-updateUploadsWithType:inRange:completion:` is called with a range of uploads that is not within the set of uploads cached locally, an exception will be thrown. 
*/

typedef enum : NSUInteger {
    kTMBOTypeImage  = 0x1,
    kTMBOTypeTopic  = 0x2,
    kTMBOTypeAudio  = 0x4,
    kTMBOTypeAvatar = 0x8,
    kTMBOTypeAny    = kTMBOTypeImage | kTMBOTypeTopic | kTMBOTypeAudio | kTMBOTypeAvatar
} kTMBOType;

typedef struct {
    NSUInteger first;
    NSUInteger last;
} TMBORange;

TMBORange TMBOMakeRange(NSUInteger first, NSUInteger last);

@interface TMBODataStore : NSObject

///----------------------
/// @name Class Singleton
///----------------------

/**
 TMBODataStore is a singleton class. All access to the class' instance method should be done using the value returned from `[TMBODataStore sharedStore]`
 
 @return The shared store object. This is created automatically as needed.
 */

+ (TMBODataStore *)sharedStore;

/**
 Sets a callback target for authentication failures. This is intended to be the App delegate, or code that is otherwise relatively global and has access to the root navigation controller.
 
 @discussion When the selector is called, API calls other than `authenticateUsername:password:completion:` will fail (and cause the target to be called again). `authenticateUsername:password:completion:` itself can also cause this target to be called if the user-provided username or password was incorrect. The owner of the modal login view should not allow it to be dismissed until the completion block to `authenticateUsername:password:completion:` is given a nil value to its error parameter, indicating that authentication was successful and a token captured.
 */

- (void)setAuthFailureTarget:(id)target selector:(SEL)sel;

///----------------------------
/// @name Accessing Upload Data
///----------------------------

/**
 Fetches locally-cached upload data.
 
 If possible, this method will initiate traffic to update the objects returned with fresh data from the server.
 
 @param type The type of upload to return
 @param near The upload id to center the request near.
 
 @return An array of `Upload` objects, up to 50 since `near` and up to 50 before `near`.
 */
- (NSArray *)cachedUploadsWithType:(kTMBOType)type near:(NSUInteger)near;

// TODO: offline support
//- (NSArray *)cachedUploadsWithType:(kTMBOType)type since:(NSUInteger)since;
//- (NSArray *)cachedUploadsWithType:(kTMBOType)type before:(NSUInteger)before;

/**
 Fetches upload data after a specified upload, from the server if required.
 
 @param type The type of upload to return
 @param since The minimum uploadid of the returned result set, inclusive.
 @param block A block that takes two arguments: a result array containing zero or more Upload objects and an `NSError` indicating the success of the operation. If the operation was successful, the `NSError` parameter will be `nil`. If the operation was successful and the result array is empty or contains only the object for `since`, then the server does not have any uploads newer than `since`.
 */
- (void)uploadsWithType:(kTMBOType)type since:(NSUInteger)since completion:(void (^)(NSArray *, NSError *))block;

/**
 Fetches upload data before a specified upload, from the server if required.
 
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
 
 @discussion Unlike other TMBODataStore methods, this method does not pass objects back to the caller via the callback block. Callers interested in specific updates to model objects are encouraged to use KVO notifications.
 
 @param type The type of upload to update
 @param range The range of uploads to update, inclusive
 @param block A block with an error argument that is called when all updates inside the range have been processed or the operation failed.
 */
- (void)updateUploadsWithType:(kTMBOType)type inRange:(TMBORange)range completion:(void (^)(NSError *))block;


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
