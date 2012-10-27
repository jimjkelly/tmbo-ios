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
    kNNSeverityTrace = 0,
    kNNSeverityDebug,
    kNNSeverityInfo,
    kNNSeverityWarn,
    kNNSeverityError,
    kNNSeverityFatal,
    kNNSeverityCount
} NNSeverity;

@interface NNLogger : NSObject
@property (nonatomic, assign) NNSeverity logLevel;
@property (nonatomic, readonly) NSString *context;
@property (nonatomic, assign) NSArray *filenames;

- (id)initWithContext:(NSString *)context orFile:(char *)filename;
- (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line userInfo:(NSDictionary *)userInfo;

+ (NNLogger *)loggerForContext:(NSString *)context orFile:(char *)filename;
+ (void)setLogLevel:(NNSeverity)level forContext:(NSString *)context orFile:(char *)filename;
+ (void)logMessage:(NSString *)message withSeverity:(NNSeverity)severity inFile:(char *)filename atLine:(NSUInteger)line forContext:(NSString *)context userInfo:(NSDictionary *)userInfo;
@end

#pragma mark Objective-C Logging macros

#define NMInternalLogUserInfoSev(uI, sev, fmt, ...) do { \
    NSString *context = nil; \
    if ([self respondsToSelector:@selector(className)]) { \
        context = [self performSelector:@selector(className)]; \
    } \
    [NNLogger logMessage:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] withSeverity:(sev) inFile:(__FILE__) atLine:(__LINE__) forContext:context userInfo:(uI)]; \
} while(0)

#define NMLogTrace(fmt, ...) NMInternalLogUserInfoSev(nil, kNNSeverityTrace, (fmt), ##__VA_ARGS__)
#define NMLogDebug(fmt, ...) NMInternalLogUserInfoSev(nil, kNNSeverityDebug, (fmt), ##__VA_ARGS__)
#define NMLogInfo(fmt, ...)  NMInternalLogUserInfoSev(nil, kNNSeverityInfo,  (fmt), ##__VA_ARGS__)
#define NMLogWarn(fmt, ...)  NMInternalLogUserInfoSev(nil, kNNSeverityWarn,  (fmt), ##__VA_ARGS__)
#define NMLogError(fmt, ...) NMInternalLogUserInfoSev(nil, kNNSeverityError, (fmt), ##__VA_ARGS__)
#define NMLogFatal(fmt, ...) NMInternalLogUserInfoSev(nil, kNNSeverityFatal, (fmt), ##__VA_ARGS__)

#define NMLogUserInfoTrace(uI, fmt, ...) NMInternalLogUserInfoSev((uI), kNNSeverityTrace, (fmt), ##__VA_ARGS__)
#define NMLogUserInfoDebug(uI, fmt, ...) NMInternalLogUserInfoSev((uI), kNNSeverityDebug, (fmt), ##__VA_ARGS__)
#define NMLogUserInfoInfo(uI, fmt, ...)  NMInternalLogUserInfoSev((uI), kNNSeverityInfo,  (fmt), ##__VA_ARGS__)
#define NMLogUserInfoWarn(uI, fmt, ...)  NMInternalLogUserInfoSev((uI), kNNSeverityWarn,  (fmt), ##__VA_ARGS__)
#define NMLogUserInfoError(uI, fmt, ...) NMInternalLogUserInfoSev((uI), kNNSeverityError, (fmt), ##__VA_ARGS__)
#define NMLogUserInfoFatal(uI, fmt, ...) NMInternalLogUserInfoSev((uI), kNNSeverityFatal, (fmt), ##__VA_ARGS__)

#define NMSetLogLevel(sev) do { \
    NSString *context = nil; \
    if ([self respondsToSelector:@selector(className)]) { \
        context = [self performSelector:@selector(className)]; \
    } \
    [NNLogger setLogLevel:(sev) forContext:context orFile:(__FILE__)]; \
} while(0)

#pragma mark C Logging macros

#define NCInternalLogUserInfoSev(uI, sev, fmt, ...) do { \
    [NNLogger logMessage:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] withSeverity:(sev) inFile:(__FILE__) atLine:(__LINE__) forContext:nil userInfo:(uI)]; \
} while(0)

#define NCLogTrace(fmt, ...) NCInternalLogUserInfoSev(nil, kNNSeverityTrace, (fmt), ##__VA_ARGS__)
#define NCLogDebug(fmt, ...) NCInternalLogUserInfoSev(nil, kNNSeverityDebug, (fmt), ##__VA_ARGS__)
#define NCLogInfo(fmt, ...)  NCInternalLogUserInfoSev(nil, kNNSeverityInfo,  (fmt), ##__VA_ARGS__)
#define NCLogWarn(fmt, ...)  NCInternalLogUserInfoSev(nil, kNNSeverityWarn,  (fmt), ##__VA_ARGS__)
#define NCLogError(fmt, ...) NCInternalLogUserInfoSev(nil, kNNSeverityError, (fmt), ##__VA_ARGS__)
#define NCLogFatal(fmt, ...) NCInternalLogUserInfoSev(nil, kNNSeverityFatal, (fmt), ##__VA_ARGS__)

#define NCLogUserInfoTrace(uI, fmt, ...) NCInternalLogUserInfoSev((uI), kNNSeverityTrace, (fmt), ##__VA_ARGS__)
#define NCLogUserInfoDebug(uI, fmt, ...) NCInternalLogUserInfoSev((uI), kNNSeverityDebug, (fmt), ##__VA_ARGS__)
#define NCLogUserInfoInfo(uI, fmt, ...)  NCInternalLogUserInfoSev((uI), kNNSeverityInfo,  (fmt), ##__VA_ARGS__)
#define NCLogUserInfoWarn(uI, fmt, ...)  NCInternalLogUserInfoSev((uI), kNNSeverityWarn,  (fmt), ##__VA_ARGS__)
#define NCLogUserInfoError(uI, fmt, ...) NCInternalLogUserInfoSev((uI), kNNSeverityError, (fmt), ##__VA_ARGS__)
#define NCLogUserInfoFatal(uI, fmt, ...) NCInternalLogUserInfoSev((uI), kNNSeverityFatal, (fmt), ##__VA_ARGS__)

#define NCSetLogLevel(sev) do { \
    [NNLogger setLogLevel:(sev) forContext:nil orFile:(__FILE__)]; \
} while(0)
