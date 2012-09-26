//
//  TMBODataStore.m
//  TMBO
//
//  Created by Scott Perry on 09/25/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBODataStore.h"

#import <CoreData/CoreData.h>

@interface TMBODataStore ()
{
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}
@end

static TMBODataStore *shared = nil;

@implementation TMBODataStore

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
    
    // ...
    
    return self;
}

#pragma mark - Public API implementation

- (NSArray *)cachedUploadsWithType:(kTMBOType)type near:(NSUInteger)near;
{
    return @[];
}

- (void)uploadsWithType:(kTMBOType)type since:(NSUInteger)since completion:(void (^)(NSArray *, NSError *))block;
{
    
}

- (void)uploadsWithType:(kTMBOType)type before:(NSUInteger)before completion:(void (^)(NSArray *, NSError *))block;
{
    
}

- (void)updateUploadsWithType:(kTMBOType)type inRange:(TMBORange)range completion:(void (^)(void))block;
{
    
}

- (void)latestIDForType:(kTMBOType)type completion:(void (^)(NSUInteger, NSError *))block;
{
    
}

- (void)authenticateUsername:(NSString *)username password:(NSString *)password completion:(void (^)(NSError *))block;
{
    
}

#pragma mark - Private API implementation

@end
