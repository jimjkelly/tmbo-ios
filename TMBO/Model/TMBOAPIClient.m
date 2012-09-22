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

@interface TMBOAPIClient ()
- (void)parsePredicate:(NSPredicate *)predicate into:(NSMutableDictionary *)dict;
@end

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

- (void)parsePredicate:(NSPredicate *)predicate into:(NSMutableDictionary *)dict;
{
    if (predicate == nil) {
    } else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *predicates = (NSCompoundPredicate *)predicate;
        
        if ([predicates compoundPredicateType] != NSAndPredicateType) {
            NotReached();
        }
        
        for (NSPredicate *p in [predicates subpredicates]) {
            [self parsePredicate:p into:dict];
        }
    } else if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparison = (NSComparisonPredicate *)predicate;
        NSString *key = [[comparison leftExpression] keyPath];
        // Constants aren't all strings, but they all can produce useful strings, which is what we're stuffing into our http args anyway
        NSString *constant = [[[comparison rightExpression] constantValue] description];
        
        if ([key isEqualToString:@"type"]) {
            // Limit query to uploads of this type
            [dict setObject:constant forKey:key];
        }
        if ([key isEqualToString:@"uploadid"]) {
            // Limit query to uploads newer, older, or equal to this id
            switch ([comparison predicateOperatorType]) {
                case NSGreaterThanOrEqualToPredicateOperatorType:
                    [dict setObject:constant forKey:@"since"];
                    break;

                case NSLessThanOrEqualToPredicateOperatorType:
                    [dict setObject:constant forKey:@"max"];
                    break;

                default:
                    NSLog(@"Predicate operator %u not supported", [comparison predicateOperatorType]);
                    NotReached();
                    break;
            }
        }
        if ([key isEqualToString:@"userid"]) {
            [dict setObject:constant forKey:@"userid"];
        }
    } else {
        // This is bad code. Don't use unsupported predicates!
        NotReached();
    }
}

#pragma mark - AFIncrementalStore

- (NSURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest
                             withContext:(NSManagedObjectContext *)context
{
    NSMutableURLRequest *mutableURLRequest = nil;
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    NSPredicate *predicates = [fetchRequest predicate];
    [self parsePredicate:predicates into:args];

    // Authentication token
    Assert(kTMBOToken);
    [args setObject:kTMBOToken forKey:@"token"];

    // TMBO API only returns up to 200 items at a time
    Assert([fetchRequest fetchLimit] <= 200);
    [args setObject:[NSString stringWithFormat:@"%u", [fetchRequest fetchLimit]] forKey:@"limit"];

    if ([fetchRequest.entityName isEqualToString:@"Upload"]) {
        mutableURLRequest = [self requestWithMethod:@"GET" path:@"getuploads.json" parameters:args];
        NSLog(@"%@", [[mutableURLRequest URL] absoluteString]);
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
