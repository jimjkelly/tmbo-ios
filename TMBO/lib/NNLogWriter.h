//
//  NNLogWriter.h
//  TMBO
//
//  Created by Scott Perry on 10/26/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NNLogger.h"

@interface NNLogWriter : NSObject

- (void)logMessage:(NSString *)message inContext:(NSString *)context withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line userInfo:(NSDictionary *)userInfo;

@end
