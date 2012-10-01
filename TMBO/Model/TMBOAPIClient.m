//
//  TMBOAPIClient.m
//  TMBO
//
//  Created by Scott Perry on 09/26/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOAPIClient.h"

#import "AFJSONRequestOperation.h"

#define kTMBOAPIBaseURL [NSURL URLWithString:@"/offensive/api.php/" relativeToURL:kTMBOBaseURL]

static TMBOAPIClient *_sharedClient = nil;

@implementation TMBOAPIClient

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
<<<<<<< HEAD
        _sharedClient = [[self alloc] initWithBaseURL:kTMBOAPIBaseURL];
        [_sharedClient setDefaultHeader:@"User-Agent" value:kTMBOUserAgent];
=======
        _sharedClient = [[TMBOAPIClient alloc] initWithBaseURL:kTMBOAPIBaseURL];
>>>>>>> upstream/develop
    });
}

+ (TMBOAPIClient *)sharedClient;
{
    Assert(_sharedClient);
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) return nil;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
<<<<<<< HEAD
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

- (NSURLRequest *)requestLoginTokenForUsername:(NSString *)username
                                   andPassword:(NSString *)password
{
    NSMutableURLRequest *mutableURLRequest = nil;
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    
    [args setObject:username forKey:@"username"];
    [args setObject:password forKey:@"password"];
    [args setObject:@"1" forKey:@"gettoken"];
    
    mutableURLRequest = [self requestWithMethod:@"GET" path:@"login.json" parameters:args];
    NSLog(@"API request: %@", [[mutableURLRequest URL] absoluteString]);
    return mutableURLRequest;
}

- (NSURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest
                             withContext:(NSManagedObjectContext *)context
{
    NSMutableURLRequest *mutableURLRequest = nil;
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    NSPredicate *predicates = [fetchRequest predicate];
    [self parsePredicate:predicates into:args];

    // Authentication token, set via TMBOLoginViewController
    NSString *TMBOToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"TMBOToken"];
    if (!TMBOToken) {
        // We set it to nothing here if it's nil above, presumably the call will 401
        // and we should be directed to the login page.  Alternatively one could
        // manually set a token here for development purposes.
        TMBOToken = @"";
    }
    
    [args setObject:TMBOToken forKey:@"token"];

    // TMBO API only returns up to 200 items at a time
    Assert([fetchRequest fetchLimit] <= 200);
    [args setObject:[NSString stringWithFormat:@"%u", [fetchRequest fetchLimit]] forKey:@"limit"];

    if ([fetchRequest.entityName isEqualToString:@"Upload"]) {
        mutableURLRequest = [self requestWithMethod:@"GET" path:@"getuploads.json" parameters:args];
    }

    NSLog(@"API request: %@", [[mutableURLRequest URL] absoluteString]);
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
=======
    [self setDefaultHeader:@"User-Agent" value:kTMBOUserAgent];
>>>>>>> upstream/develop
    
    return self;
}

@end
