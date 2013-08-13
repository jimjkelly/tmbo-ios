//
//  NNLogWriter.m
//  TMBO
//
//  Created by Scott Perry on 10/26/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "NNLogWriter.h"

@implementation NNLogWriter

- (void)logMessage:(NSString *)message inContext:(NSString *)context withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line userInfo:(NSDictionary *)userInfo;
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Subclasses of %@ must override %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
