//
//  NNConsoleLogWriter.m
//  TMBO
//
//  Created by Scott Perry on 10/26/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "NNConsoleLogWriter.h"

@implementation NNConsoleLogWriter

- (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line userInfo:(NSDictionary *)userInfo;
{
    NSString *shortFilename = [[[NSString alloc] initWithCString:(filename) encoding:NSUTF8StringEncoding] lastPathComponent];
    // TODO: need severity
    NSLog(@"%@:%d: %@ %@", shortFilename, line, message, userInfo ? [NSString stringWithFormat:@" userInfo: %@", userInfo] : @"");
}

@end
