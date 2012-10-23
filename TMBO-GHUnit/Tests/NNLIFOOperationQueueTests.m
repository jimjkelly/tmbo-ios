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

static NSTimeInterval operationTime = 0.1f;
#define operationTimeout ((NSTimeInterval)(operationTime * 1.2f))

@implementation NNLIFOOperationQueueTests

- (void)testOperationRun;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];

    id mock = [self mockOperationToRun];
    [opq addOperation:mock forKey:@"test"];
    
    [self operationTimeoutWait];
    
    [mock verify];
    
    mock = [self mockOperationToRun];
    [opq addOperation:mock forKey:@"test"];
    
    [self operationTimeoutWait];
    
    [mock verify];
}

- (void)testSuspend;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    opq.suspended = YES;
    
    id mock = [self mockOperationToRun];
    [opq addOperation:mock forKey:@"test"];
    
    [self operationTimeoutWait];
    GHAssertThrows([mock verify], @"");
    
    opq.suspended = NO;
    
    [self operationTimeoutWait];

    [mock verify];
}

- (void)testReplacement;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    opq.suspended = YES;
    
    NSString *dupKey = @"test";
    id cancelMock = [self mockOperationToCancel];
    [opq addOperation:cancelMock forKey:dupKey];
    
    id runMock = [self mockOperationToRun];
    [opq addOperation:runMock forKey:dupKey];
    
    opq.suspended = NO;
    
    [self operationTimeoutWait];
    
    [cancelMock verify];
    [runMock verify];
}

- (void)testReplacementWhileRunning;
{
    NNLIFOOperationQueue *opq = [[NNLIFOOperationQueue alloc] init];
    
    NSString *dupKey = @"test";
    id runMock = [self mockOperationToRun];
    [opq addOperation:runMock forKey:dupKey];

    [self halfOperationWait];
    
    id cancelMock = [self mockOperationToCancel];
    [opq addOperation:cancelMock forKey:dupKey];
    
    [self operationTimeoutWait];

    [cancelMock verify];
    [runMock verify];
}

#pragma mark Mocks

- (id)mockOperationToRun;
{
    id mock = [OCMockObject mockForClass:[NSOperation class]];
    
    [[[mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] isReady];
    [(NSOperation *)[mock expect] start];
    [(NSOperation *)[[mock stub] andCall:@selector(operationWait) onObject:self] waitUntilFinished];
    
    return mock;
}

- (id)mockOperationToCancel;
{
    id mock = [OCMockObject mockForClass:[NSOperation class]];
    
    [(NSOperation *)[mock expect] cancel];
    [(NSOperation *)[mock expect] start];
    
    return mock;
}

#pragma mark Timers

- (void)operationWait;
{
    usleep((useconds_t)(operationTime * 1000000.0f));
}

- (void)operationTimeoutWait;
{
    usleep((useconds_t)(operationTimeout * 1000000.0f));
}

- (void)halfOperationWait;
{
    usleep((useconds_t)(operationTime * 1000000.0f));
}

#pragma mark GHUnit

- (BOOL)shouldRunOnMainThread;
{
    return NO;
}

@end
