//
//  TMBOIncrementalStore.m
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOIncrementalStore.h"

#import "TMBOAPIClient.h"

@implementation TMBOIncrementalStore

+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
    return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model {
    return nil;
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TMBO" withExtension:@"xcdatamodeld"]];
}

- (id<AFIncrementalStoreHTTPClient>)HTTPClient {
    return [TMBOAPIClient sharedClient];
}

@end
