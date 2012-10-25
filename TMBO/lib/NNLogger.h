//
//  NNLogger.h
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

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kNNSeverityTrace,
    kNNSeverityDebug,
    kNNSeverityInfo,
    kNNSeverityWarn,
    kNNSeverityError,
    kNNSeverityFatal
} NNSeverity;

@interface NNLogger : NSObject
@property (nonatomic, assign) NNSeverity logLevel;
@property (nonatomic, readonly) NSString *context;
@property (nonatomic, assign) NSArray *filenames;

- (id)initWithContext:(NSString *)context orFile:(char *)filename;
- (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line;

+ (NNLogger *)loggerForContext:(NSString *)context orFile:(char *)filename;
+ (void)setLogLevel:(NNSeverity)level forContext:(NSString *)context orFile:(char *)filename;
+ (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line forContext:(NSString *)context;
@end

// Is there a way to determine via macro if you are inside C or obj-c code? there's __OBJC__ but that still isn't good enough because self might not be defined
#define NNInternalLogSev(sev, fmt, ...) do { \
    NSString *context = nil; \
    if ([self respondsToSelector:@selector(className)]) { \
        context = [self performSelector:@selector(className)]; \
    } \
    [NNLogger logMessage:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] withSeverity:(sev) inFile:(__FILE__) atLine:(__LINE__) forContext:context]; \
} while(0)

#define NNLogTrace(fmt, ...) NNInternalLogSev(kNNSeverityTrace, (fmt), ##__VA_ARGS__)
#define NNLogDebug(fmt, ...) NNInternalLogSev(kNNSeverityDebug, (fmt), ##__VA_ARGS__)
#define NNLogInfo(fmt, ...)  NNInternalLogSev(kNNSeverityInfo,  (fmt), ##__VA_ARGS__)
#define NNLogWarn(fmt, ...)  NNInternalLogSev(kNNSeverityWarn,  (fmt), ##__VA_ARGS__)
#define NNLogError(fmt, ...) NNInternalLogSev(kNNSeverityError, (fmt), ##__VA_ARGS__)
#define NNLogFatal(fmt, ...) NNInternalLogSev(kNNSeverityFatal, (fmt), ##__VA_ARGS__)

#define NNSetLogLevel(sev) do { \
    NSString *context = nil; \
    if ([self respondsToSelector:@selector(className)]) { \
        context = [self performSelector:@selector(className)]; \
    } \
    [NNLogger setLogLevel:(sev) forContext:context orFile:(__FILE__)]; \
} while(0)