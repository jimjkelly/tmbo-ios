//
//  NNLIFOOperationQueueTests.m
//  TMBO
//
//  Created by Scott Perry on 10/23/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNLIFOOperationQueueTests.h"

#import <OCMock/OCMock.h>

#import "NNLIFOOperationQueue.h"
#import "NNLogger.h"

@interface NNMockOperation : NSOperation
@property (nonatomic, strong) dispatch_semaphore_t workSemaphore;
@property (nonatomic, strong) dispatch_semaphore_t mockSemaphore;
@property (nonatomic, assign) BOOL started;
+ (NNMockOperation *)operation;
- (void)finishJob;
@end
@implementation NNMockOperation
+ (NNMockOperation *)operation;
{
    return [[NNMockOperation alloc] init];
}

- (id)init;
{
    self = [super init];
    BailUnless(self, nil);
    _workSemaphore = dispatch_semaphore_create(0);
    _mockSemaphore = dispatch_semaphore_create(0);
    _started = NO;
    return self;
}

- (void)main;
{
    self.started = YES;
    dispatch_semaphore_wait(self.workSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(self.mockSemaphore);
}

- (void)finishJob;
{
    dispatch_semaphore_signal(self.workSemaphore);
    if (dispatch_semaphore_wait(self.mockSemaphore, dispatch_time(DISPATCH_TIME_NOW, 1000000000))) {
        @throw [NSException exceptionWithName:@"OperationNeverRanException" reason:@"Operation never ran!" userInfo:nil];
    }
    // Give the pq enough time to queue the next job
    usleep(10000);
}
@end

@implementation NNLIFOOperationQueueTests

- (void)testOperationRun;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    
    NNMockOperation *mock;
    
    mock = [NNMockOperation operation];
    [opq addOperation:mock forKey:@"test"];
    [mock finishJob];
    GHAssertTrue(mock.started, @"");
    
    mock = [NNMockOperation operation];
    [opq addOperation:mock forKey:@"test"];
    [mock finishJob];
    GHAssertTrue(mock.started, @"");
}

- (void)testSuspend;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    opq.suspended = YES;
    
    NNMockOperation *mock = [NNMockOperation operation];
    [opq addOperation:mock forKey:@"test"];
    
    GHAssertFalse(mock.started, @"");
    
    opq.suspended = NO;
    
    [mock finishJob];
    GHAssertTrue(mock.started, @"");
}

- (void)testReplacement;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    opq.suspended = YES;
    
    NSString *dupKey = @"test";
    id cancelMock = [self mockOperationToCancel];
    [opq addOperation:cancelMock forKey:dupKey];
    
    NNMockOperation *runMock = [NNMockOperation operation];
    [opq addOperation:runMock forKey:dupKey];
    
    opq.suspended = NO;
    
    [runMock finishJob];
    
    [cancelMock verify];
    GHAssertTrue(runMock.started, @"");
}

- (void)testReplacementWhileRunning;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    
    NSString *dupKey = @"test";
    NNMockOperation *runMock = [NNMockOperation operation];
    [opq addOperation:runMock forKey:dupKey];

    while (!runMock.started) {
        usleep(100);
    }
    
    id cancelMock = [self mockOperationToCancel];
    [opq addOperation:cancelMock forKey:dupKey];
    // addOperation is async, which is good for real life, but bad for testing. wait a tick to make sure it gets added to the queue
    usleep(10000);
    
    [runMock finishJob];

    [cancelMock verify];
    GHAssertTrue(runMock.started, @"");
}

- (void)testSuspendWhileRunning;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    
    opq.suspended = YES;
    
    NNMockOperation *mock1 = [NNMockOperation operation];
    [opq addOperation:mock1 forKey:@"test"];
    
    NNMockOperation *mock2 = [NNMockOperation operation];
    [opq addOperation:mock2 forKey:@"test2"];
    
    opq.suspended = NO;

    while (!mock2.started) {
        usleep(100);
    }
    
    opq.suspended = YES;

    [mock2 finishJob];
    GHAssertTrue(mock2.started, @"");
    GHAssertFalse(mock1.started, @"");

    opq.suspended = NO;
    [mock1 finishJob];
    GHAssertTrue(mock1.started, @"");
}

#pragma mark Mocks

- (id)mockOperationToCancel;
{
    id mock = [OCMockObject mockForClass:[NSOperation class]];
    
    [(NSOperation *)[mock expect] cancel];
    [(NSOperation *)[mock expect] start];
    
    return mock;
}

#pragma mark GHUnit

- (void)setUpClass;
{
    [NNLogger setLogLevel:kNNSeverityTrace forContext:@"NNLIFOOperationQueue" orFile:(__FILE__)];
    NMSetLogLevel(kNNSeverityTrace);
    NMLogDebug(@"Set up logging for %@ and %@", @"NNLIFOOperationQueue", @"NNLIFOOperationQueueTests");
}

- (BOOL)shouldRunOnMainThread;
{
    return NO;
}

@end
