//
//  TMBOAPIClient.m
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOAPIClient.h"

#import "TMBOJSONRequestOperation.h"

static NSString * const kTMBOAPIBaseURLString = @"https://thismight.be/offensive/api.php/";

@implementation TMBOAPIClient

+ (TMBOAPIClient *)sharedClient {
    static TMBOAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTMBOAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[TMBOJSONRequestOperation class]];
    
    return self;
}

#pragma mark - AFIncrementalStore

- (NSURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest
                             withContext:(NSManagedObjectContext *)context
{
    NSMutableURLRequest *mutableURLRequest = nil;
    if ([fetchRequest.entityName isEqualToString:@"Upload"]) {
        // TODO: tailor arguments for request based on NSFetchRequest shit
        mutableURLRequest = [self requestWithMethod:@"GET" path:@"getuploads.json" parameters:@{@"token" : kTMBOToken}];
    }
    
    return mutableURLRequest;
}

#define becomes(jsonkey, managedkey) [mutablePropertyValues setValue:[representation valueForKey:(jsonkey)] forKey:(managedkey)]
- (NSDictionary *)attributesForRepresentation:(NSDictionary *)representation
                                     ofEntity:(NSEntityDescription *)entity
                                 fromResponse:(NSHTTPURLResponse *)response
{
    NSMutableDictionary *mutablePropertyValues = [[super attributesForRepresentation:representation ofEntity:entity fromResponse:response] mutableCopy];
    if ([entity.name isEqualToString:@"Upload"]) {
        becomes(@"vote_bad", @"badVotes");
        becomes(@"link_file", @"fileURL");
        becomes(@"vote_good", @"goodVotes");
        becomes(@"last_active", @"lastActive");
        becomes(@"vote_repost", @"repostVotes");
        becomes(@"link_thumb", @"thumbURL");
        becomes(@"vote_tmbo", @"tmboVotes");
        becomes(@"id", @"uploadid");
    }
    
    return mutablePropertyValues;
}

- (BOOL)shouldFetchRemoteAttributeValuesForObjectWithID:(NSManagedObjectID *)objectID
                                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    return NO;
}

- (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship
                               forObjectWithID:(NSManagedObjectID *)objectID
                        inManagedObjectContext:(NSManagedObjectContext *)context
{
    return NO;
}

@end
