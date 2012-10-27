//
//  NNLogger.m
//  TMBO
//
//  Created by Scott Perry on 10/24/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNLogger.h"

#import "NNLogWriter.h"
#ifdef DEBUG
#import "NNConsoleLogWriter.h"
#endif

static NSString * const kRootLoggerContext = @"root";

static NSMutableDictionary *contextForFilename;
static NSMutableDictionary *loggerForContext;
static NSMutableSet *logWriters;

@implementation NNLogger

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        contextForFilename = [[NSMutableDictionary alloc] init];
        loggerForContext = [[NSMutableDictionary alloc] init];
        logWriters = [[NSMutableSet alloc] init];
        
#ifdef DEBUG
        [logWriters addObject:[[NNConsoleLogWriter alloc] init]];
#endif
        [NNLogger loggerForContext:kRootLoggerContext orFile:NULL];
    });
}

- (id)initWithContext:(NSString *)context orFile:(char *)filename;
{
    if ([loggerForContext objectForKey:context]) {
        @throw [NSException exceptionWithName:@"NNLoggerSingletonException" reason:@"A logger instance for this context already exists" userInfo:@{ @"context" : context, @"logger" : [loggerForContext objectForKey:context] }];
    }
    
    [NNLogger associateFile:filename withContext:context];
    
    self = [super init];
    BailUnless(self, nil);
    
    self.logLevel = kNNSeverityInfo;
    
    [loggerForContext setObject:self forKey:context];
    
    return self;
}

- (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line userInfo:(NSDictionary *)userInfo;
{
    if (severity < self.logLevel) {
        return;
    }
    
    for (NNLogWriter *writer in logWriters) {
        [writer logMessage:message withSeverity:severity inFile:filename atLine:line userInfo:userInfo];
    }
}

+ (NNLogger *)loggerForContext:(NSString *)context orFile:(char *)filename;
{
    context = [NNLogger associateFile:filename withContext:context];
    
    return [loggerForContext objectForKey:context] ?: [[NNLogger alloc] initWithContext:context orFile:filename];
}

+ (void)setLogLevel:(NNSeverity)level forContext:(NSString *)context orFile:(char *)filename;
{
    NNLogger *logger = [NNLogger loggerForContext:context orFile:filename];
    
    logger.logLevel = level;
}

+ (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line forContext:(NSString *)context userInfo:(NSDictionary *)userInfo;
{
    NNLogger *logger = [NNLogger loggerForContext:context orFile:filename];
    
    [logger logMessage:message withSeverity:severity inFile:filename atLine:line userInfo:userInfo];
}

#pragma mark Private methods

+ (NSString *)associateFile:(char *)cFilename withContext:(NSString *)context;
{
    if (!cFilename && ![context isEqualToString:kRootLoggerContext]) {
        @throw [NSException exceptionWithName:@"NNLoggerInvalidFilenameException" reason:@"Logger methods only accept valid filenames (are you not using the macros?)" userInfo:nil];
    }

    if (cFilename) {
        NSString *filename = [NSString stringWithCString:cFilename encoding:NSUTF8StringEncoding];
        
        if (context && filename) {
            [contextForFilename setObject:context forKey:filename];
        }
        
        if (!context) {
            context = [contextForFilename objectForKey:filename];
        }
        
        if (!context) {
            context = kRootLoggerContext;
        }
    }
    
    Assert(context);
    
    return context;
}

@end
