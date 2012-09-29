//
//  TMBODataStore.m
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

#import "TMBODataStore.h"

#import <CoreData/CoreData.h>

#import "AFHTTPRequestOperation.h"
#import "ISO8601DateFormatter.h"
#import "TMBOAPIClient.h"
#import "TMBOUpload.h"

@interface TMBODataStore ()
{
    NSDictionary *keyRepresentationForUpload;
    
    __weak id authFailedTarget;
    SEL authFailedAction;
}

@property (nonatomic, strong, readonly) TMBOAPIClient *client;

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectContext *context;

- (id)callAPIMethod:(NSString *)method withArgs:(NSDictionary *)args;
- (TMBOUpload *)addOrUpdateUploadWithData:(NSDictionary *)data;
- (NSString *)typeStringForType:(kTMBOType)type;
- (id)parseUploadData:(id)rawData;
@end

static TMBODataStore *shared = nil;
static const NSUInteger kQueryLimit = 50;

@implementation TMBODataStore

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize context = _context;
@synthesize client = _client;

#pragma mark - Singleton creation/dispatch

+ (void)initialize;
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
}

+ (TMBODataStore *)sharedStore;
{
    return shared;
}

- (id)init;
{
    if (shared) {
        NSLog(@"Warning: initializing multiple instances of singleton class %@", NSStringFromClass([self class]));
    }
    
    self = [super init];
    if (!self) return nil;
    
    keyRepresentationForUpload = @{
        @"vote_bad" : @"badVotes",
        @"link_file" : @"fileURL",
        @"vote_good" : @"goodVotes",
        @"last_active" : @"lastActive",
        @"vote_repost" : @"repostVotes",
        @"link_thumb" : @"thumbURL",
        @"vote_tmbo" : @"tmboVotes",
        @"id" : @"uploadid"
    };

    return self;
}

#pragma mark Initialization helpers

- (NSManagedObjectModel *)managedObjectModel;
{
    if (_managedObjectModel) return _managedObjectModel;
    
    @synchronized(_managedObjectModel) {
        if (_managedObjectModel) return _managedObjectModel;
        
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TMBO" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
{
    if (_persistentStoreCoordinator) return _persistentStoreCoordinator;
    
    @synchronized(_persistentStoreCoordinator) {
        if (_persistentStoreCoordinator) return _persistentStoreCoordinator;
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        NSError *error = nil;
        NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption : @(YES),
        NSMigratePersistentStoresAutomaticallyOption : @(YES),
        };
        
        // TODO: Change this to SQLite someday
        [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:options error:&error];
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)context;
{
    if (_context) return _context;
    
    @synchronized(_context) {
        if (_context) return _context;

        _context = [[NSManagedObjectContext alloc] init];
        [_context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    }
    
    return _context;
}

- (TMBOAPIClient *)client;
{
    if (_client) return _client;
    
    @synchronized(_client) {
        if (_client) return _client;
        
        _client = [TMBOAPIClient sharedClient];
    }
    
    return _client;

}

#pragma mark - Public API implementation

- (NSArray *)cachedUploadsWithType:(kTMBOType)type near:(NSUInteger)near;
{
    // Request against the model. 50 newer and 50 older than near.
    return @[];
}

- (void)uploadsWithType:(kTMBOType)type since:(NSUInteger)since completion:(void (^)(NSArray *, NSError *))block;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Get the raw parsed data from the API call
        id rawData = nil;
        {
            NSString *method = @"getuploads";
            NSMutableDictionary *args = [@{@"since" : @(since), @"limit" : @(kQueryLimit)} mutableCopy];
            if ([self typeStringForType:type]) {
                [args setObject:[self typeStringForType:type] forKey:@"type"];
            }
            rawData = [self callAPIMethod:method withArgs:args];
        }
        
        // Turn the parsed data into model objects
        id result = [self parseUploadData:rawData];
        
        // Handle error in API call or parsing
        if ([result isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)result;
            NSLog(@"API call returned error: %@", [error localizedDescription]);
            block(nil, error);
            return;
        }
        Assert([result isKindOfClass:[NSArray class]]);
        
        block((NSArray *)result, nil);
    });
}

- (void)uploadsWithType:(kTMBOType)type before:(NSUInteger)before completion:(void (^)(NSArray *, NSError *))block;
{
    NotTested();
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Get the raw parsed data from the API call
        id rawData = nil;
        {
            NSString *method = @"getuploads";
            NSMutableDictionary *args = [@{@"before" : @(before), @"limit" : @(kQueryLimit)} mutableCopy];
            if ([self typeStringForType:type]) {
                [args setObject:[self typeStringForType:type] forKey:@"type"];
            }
            rawData = [self callAPIMethod:method withArgs:args];
        }
        
        // Turn the parsed data into model objects
        id result = [self parseUploadData:rawData];
        
        // Handle error in API call or parsing
        if ([result isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)result;
            NSLog(@"API call returned error: %@", [error localizedDescription]);
            block(nil, error);
            return;
        }
        Assert([result isKindOfClass:[NSArray class]]);
        
        block((NSArray *)result, nil);
    });
}

- (void)latestUploadsWithType:(kTMBOType)type completion:(void (^)(NSArray *, NSError *))block;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Get the raw parsed data from the API call
        id rawData = nil;
        {
            NSString *method = @"getuploads";
            NSMutableDictionary *args = [@{@"limit" : @(kQueryLimit)} mutableCopy];
            if ([self typeStringForType:type]) {
                [args setObject:[self typeStringForType:type] forKey:@"type"];
            }
            rawData = [self callAPIMethod:method withArgs:args];
        }
        
        // Turn the parsed data into model objects
        id result = [self parseUploadData:rawData];
        
        // Handle error in API call or parsing
        if ([result isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)result;
            NSLog(@"API call returned error: %@", [error localizedDescription]);
            block(nil, error);
            return;
        }
        Assert([result isKindOfClass:[NSArray class]]);
        
        block((NSArray *)result, nil);
    });
}

- (void)updateUploadsWithType:(kTMBOType)type inRange:(TMBORange)range completion:(void (^)(void))block;
{
    Assert(NO);
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        block();
    });
}

- (void)latestIDForType:(kTMBOType)type completion:(void (^)(NSUInteger, NSError *))block;
{
    Assert(NO);
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        block(112, nil);
    });
}

- (void)authenticateUsername:(NSString *)username password:(NSString *)password completion:(void (^)(NSError *))block;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Get the raw parsed data from the API call
        id result = nil;
        {
            NSString *method = @"login";
            NSDictionary *args = @{
                @"limit" : @(kQueryLimit),
                @"username" : username,
                @"password" : password,
                @"gettoken" : @(1)
            };
            result = [self callAPIMethod:method withArgs:args];
        }
        
        // Handle error in API call or parsing
        if ([result isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)result;
            NSLog(@"API call returned error: %@", [error localizedDescription]);
            block(error);
            return;
        }
        Assert([result isKindOfClass:[NSDictionary class]]);
        NSDictionary *dict = (NSDictionary *)result;
        
        /*
         {
         "tokenid":"2k2a97vtpdmjmdpzrlpkpuhjpyrx9d6b",
         "userid":"1",
         "issued_to":" (no name)",
         "issue_date":"2012-02-20 05:19:26",
         "last_used":"0000-00-00 00:00:00"
         }
         */
        NSLog(@"Successfully generated token %@ for userid %@ for application \"%@\" on %@",
              [dict objectForKey:@"tokenid"], [dict objectForKey:@"userid"], [dict objectForKey:@"issued_to"], [dict objectForKey:@"issue_date"]);
        
        [[NSUserDefaults standardUserDefaults] setValue:[dict objectForKey:@"tokenid"] forKey:@"TMBOToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        block(nil);
    });
}

#pragma mark - Authentication failure methods

- (void)setAuthFailureTarget:(id)target selector:(SEL)sel;
{
    authFailedTarget = target;
    authFailedAction = sel;
    Assert([target respondsToSelector:sel]);
}

#pragma mark - Private API implementation

- (id)callAPIMethod:(NSString *)method withArgs:(NSDictionary *)args;
{
    Assert(kTMBOToken);
    // if Assert -> [[NSUserDefaults standardUserDefaults] setValue:<#(NSString *)token#> forKey:@"TMBOToken"]; [[NSUserDefaults standardUserDefaults] synchronize]; DebugBreak(); // <- Don't forget to re-comment this line and remove your token!

    // Return type for method should be json
    method = [method stringByAppendingString:@".json"];
    
    // Add global arguments
    NSMutableDictionary *mutableArgs = [args mutableCopy];
    {
        if (kTMBOToken) {
            [mutableArgs setObject:kTMBOToken forKey:@"token"];
        }
    }
    
    // Build a result object
    __block id result = nil;
    
    // Block until operation is complete
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    // Build request operation
    NSURLRequest *request = [self.client requestWithMethod:@"GET" path:method parameters:mutableArgs];
    AFHTTPRequestOperation *reqOp = [self.client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        result = responseObject;
        
        dispatch_semaphore_signal(sem);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([[operation response] statusCode] == 401) {
            if (authFailedTarget) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [authFailedTarget performSelector:authFailedAction];
                #pragma clang diagnostic pop
            }
        } else {
            // TODO: create nserrors properly for the following:
            /*
             400 Bad Request - The call is erroneous. The body will contain debugging information.
             403 Forbidden - This content is not available to you.
             404 Not Found - The function being requested does not exist.
             500 Internal Server Error - kaboom. Please report if reproducible.
             502 Bad Gateway - TMBO is down for maintenance. Please wait a few minutes and try your call again.
             503 Service Unavailable - Refusal. You have attempted to log in too many times in a rolling 30 minute period and you are blocked from any more attempts. Wait and try again later.
             */
            NSLog(@"Error: %@ -> %@", operation, error);
            NotTested();
        }
        result = error;
        
        dispatch_semaphore_signal(sem);
    }];
    
    [self.client enqueueHTTPRequestOperation:reqOp];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

- (TMBOUpload *)addOrUpdateUploadWithData:(NSDictionary *)data;
{
    // TODO: Check that required values are present
    if (![data objectForKey:@"id"]) {
        // TODO: Bad data received from the API!
        NotTested();
    }
        
    // TODO: Get existing upload object, or create a new one
    TMBOUpload *upload = nil;
    {
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Upload" inManagedObjectContext:self.context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        
        // Set example predicate and sort orderings...
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"uploadid = %@", [data objectForKey:@"id"]];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *array = [self.context executeFetchRequest:request error:&error];
        if (array == nil) {
            // Deal with error...
            NSLog(@"array was nil?");
            NotTested();
        } else if ([array count]) {
            Assert([array count] == 1);
            upload = [array lastObject];
        } else {
            Assert([array count] == 0);
            upload = [[TMBOUpload alloc]
                      initWithEntity:entityDescription
                      insertIntoManagedObjectContext:self.context];
        }
    }

    for (NSString *key in data) {
        id value = [data objectForKey:key];
        
        // Make sure we have the right variable name for the receiver
        NSString *varname = nil;
        {
            if ([keyRepresentationForUpload objectForKey:key]) {
                varname = [keyRepresentationForUpload objectForKey:key];
            } else {
                varname = key;
            }
        }
        
        // Check that the variable exists in the receiver
        if ([TMBOUpload typeFor:varname] == nil) {
            continue;
        }
        
        // Build a selector for the receiver's appropriate setter method
        SEL setter = NULL;
        {
            NSString *firstChar = [[varname substringToIndex:1] uppercaseString];
            setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", firstChar, [varname substringFromIndex:1]]);
        }
        
        // Check that the parameter is correctly-typed
        if (![value isKindOfClass:[TMBOUpload typeFor:varname]]) {
            if ([value isKindOfClass:[NSString class]] && [TMBOUpload typeFor:varname] == [NSDate class]) {
                [NSTimeZone setDefaultTimeZone:kServerTimeZone];
                // do we need to save the device's current time zone?
                NSDate *date = [[[ISO8601DateFormatter alloc] init] dateFromString:value];
                if ([date compare:kDawnOfTime] == NSOrderedAscending) {
                    NSLog(@"Parsed key %@ (%@) as date, got %@", varname, value, date);
                    NotTested();
                }
                value = date;
            } else {
                NSLog(@"Not handled: %@ should be of type %@, but is actually type %@", varname, [TMBOUpload typeFor:varname], [value class]);
                NotTested();
                // The setter below will throw an exception.
            }
        }
        
        // Set the value
        Assert([upload respondsToSelector:setter]);
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [upload performSelector:setter withObject:value];
        #pragma clang diagnostic pop
    }
    
    return upload;
}

- (NSString *)typeStringForType:(kTMBOType)type;
{
    switch (type) {
        case kTMBOTypeAudio:
            return @"audio";
        case kTMBOTypeAvatar:
            return @"avatar";
        case kTMBOTypeImage:
            return @"image";
        case kTMBOTypeTopic:
            return @"topic";
        case kTMBOTypeAny:
            return nil;
    }
    NotReached();
}

- (id)parseUploadData:(id)parsedData;
{
    Assert(parsedData);
    
    // If we inherited an error, pass it on
    if ([parsedData isKindOfClass:[NSError class]]) return parsedData;
    
    // Consistency check and type cast
    Assert([parsedData isKindOfClass:[NSArray class]]);
    NSArray *arrayData = (NSArray *)parsedData;
    
    // Process results
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[arrayData count]];
    for (NSDictionary *upData in arrayData) {
        Assert([upData isKindOfClass:[NSDictionary class]]);
        TMBOUpload *up = [self addOrUpdateUploadWithData:upData];
        if (up) {
            [result addObject:up];
        }
    }
    [result sortUsingComparator:kUploadComparator];
    
    return result;
}

@end
