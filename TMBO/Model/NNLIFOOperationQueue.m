//
//  NNLIFOOperationQueue.m
//  TMBO
//
//  Created by Scott Perry on 10/22/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNLIFOOperationQueue.h"

#import "NNLogger.h"

@interface NNInternalOperationWrapper : NSObject
@property (nonatomic, strong) NSOperation *operation;
@property (nonatomic, strong) id<NSCopying> key;
@property (nonatomic, assign) NSUInteger seq;
@end

static NSComparator priorityQueueComparator = ^(id obj1, id obj2) {
    NSUInteger seq1 = [obj1 isKindOfClass:[NSNumber class]] ? [obj1 unsignedIntegerValue] : [obj1 seq];
    NSUInteger seq2 = [obj2 isKindOfClass:[NSNumber class]] ? [obj2 unsignedIntegerValue] : [obj2 seq];

    return (NSComparisonResult)[@(seq1) compare:@(seq2)];
};

@implementation NNInternalOperationWrapper
@end

@interface NNLIFOOperationQueue ()

@property (nonatomic, strong) NSMutableArray *priorityQueue;
@property (nonatomic, strong) NSMutableDictionary *keyDict;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) NSUInteger seq;
@property (nonatomic, strong) dispatch_queue_t soul;

@end

@implementation NNLIFOOperationQueue

- (id)init;
{
    self = [super init];
    BailUnless(self, nil);
    
    _soul = dispatch_queue_create([[self description] UTF8String], DISPATCH_QUEUE_SERIAL);
    
    _priorityQueue = [[NSMutableArray alloc] init];
    _keyDict = [[NSMutableDictionary alloc] init];
    _running = NO;
    _seq = 0;
    
    return self;
}

- (void)addOperation:(NSOperation *)operation forKey:(id<NSCopying>)key;
{
    dispatch_async(self.soul, ^{
        NNInternalOperationWrapper *wrap = [self.keyDict objectForKey:key];
        if (wrap) {
            NMLogDebug(@"Adding operation 0x%p to queue 0x%p (replacing existing operation with key \"%@\")", operation, self, key);
            [self removeWrappedOperationWithKey:wrap.key];
            wrap = nil;
        } else {
            NMLogDebug(@"Added operation 0x%p to queue 0x%p (key \"%@\")", operation, self, key);
        }
        
        wrap = [[NNInternalOperationWrapper alloc] init];
        wrap.operation = operation;
        wrap.key = key;
        wrap.seq = self.seq++;
        [self.priorityQueue addObject:wrap];
        [self.keyDict setObject:wrap forKey:key];
        [self worker];
    });
}

- (void)cancelAllOperations;
{
    dispatch_async(self.soul, ^{
        while ([self.priorityQueue count]) {
            [self removeWrappedOperationWithKey:((NNInternalOperationWrapper *)[self.priorityQueue lastObject]).key];
        }
    });
}

- (void)setSuspended:(BOOL)suspended;
{
    dispatch_async(self.soul, ^{
        if (!suspended) {
            NMLogInfo(@"Resuming queue 0x%p", self);
            [self worker];
        } else {
            NMLogInfo(@"Suspended queue 0x%p", self);
        }
        _suspended = suspended;
    });
}

#pragma mark Properties

- (NSUInteger)operationCount;
{
    return [self.keyDict count];
}

- (NSArray *)operations;
{
    NSMutableArray *operations = [NSMutableArray array];

    dispatch_sync(self.soul, ^{
        for (id obj in self.priorityQueue) {
            if (![obj isKindOfClass:[NNInternalOperationWrapper class]]) continue;
            [operations addObject:[obj operation]];
        }
    });

    return operations;
}

#pragma mark Private

- (void)removeWrappedOperationWithKey:(id<NSCopying>)key;
{
    // This sucks and I'm told by People that there will be a better way to do exacty this check in the future.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    Assert(dispatch_get_current_queue() == self.soul);
#pragma clang diagnostic pop
    
    NNInternalOperationWrapper *wrap;
    
    wrap = [self.keyDict objectForKey:key];
    if (!wrap) return;
    
    NSUInteger index = [self.priorityQueue indexOfObject:wrap inSortedRange:NSMakeRange(0, [self.priorityQueue count]) options:NSBinarySearchingFirstEqual usingComparator:priorityQueueComparator];
    if (index == NSNotFound) {
        Assert(index != NSNotFound);
    }
    
    NMLogDebug(@"Removing operation 0x%p from queue 0x%p (key \"%@\")", wrap.operation, self, key);
    [self.keyDict removeObjectForKey:wrap.key];
    // NSArray is still a list inside, so removing from the middle can be expensive. Mitigate this by replacing operations with tombstone objects.
    [self.priorityQueue replaceObjectAtIndex:index withObject:@(wrap.seq)];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [wrap.operation cancel];
        [wrap.operation start];
    });
}

- (NNInternalOperationWrapper *)nextAvailableOperation;
{
    // This sucks and I'm told by People that there will be a better way to do exacty this check in the future.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    Assert(dispatch_get_current_queue() == self.soul);
#pragma clang diagnostic pop
    
    // Nothing to run if queue is suspended
    if (self.suspended || !self.running) {
        self.running = NO;
        return nil;
    }
    
    NNInternalOperationWrapper *wrap = nil;
    NSUInteger watchdog = 0;
    void (^removeTombstones)() = ^{
        while ([[self.priorityQueue lastObject] isKindOfClass:[NSNumber class]]) {
            [self.priorityQueue removeLastObject];
        }
    };
    
    removeTombstones();
    
    while(watchdog < [self.priorityQueue count] && ![((NNInternalOperationWrapper *)[self.priorityQueue lastObject]).operation isReady]) {
        // Need to use KVO to restart the queue when an unprepared operation becomes ready. For now, all operations should be ready to go so there's no rush to implement this yet.
        Assert([((NNInternalOperationWrapper *)[self.priorityQueue lastObject]).operation isReady]);
        watchdog++;
        [self.priorityQueue insertObject:[self.priorityQueue lastObject] atIndex:0];
        [self.priorityQueue removeLastObject];
        removeTombstones();
    }
    
    if (![((NNInternalOperationWrapper *)[self.priorityQueue lastObject]).operation isReady]) {
        self.running = NO;
        return nil;
    }
    
    wrap = [self.priorityQueue lastObject];

    
    [self.priorityQueue removeLastObject];
    Assert([self.keyDict objectForKey:wrap.key]);
    [self.keyDict removeObjectForKey:wrap.key];
    
    return wrap;
}

- (void)worker;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __block BOOL shouldAbort = NO;
        dispatch_sync(self.soul, ^{
            if (self.suspended || self.running || ![self.priorityQueue count]) {
                if (self.suspended) {
                    NMLogTrace(@"Worker thread called, but queue 0x%p is suspended", self);
                } else if (self.running) {
                    NMLogTrace(@"Worker thread already running for queue 0x%p", self);
                } else if (![self.priorityQueue count]) {
                    NMLogWarn(@"Worker thread called with no jobs for queue 0x%p", self);
                }
                shouldAbort = YES;
            } else {
                self.running = YES;
            }
        });
        if (shouldAbort) {
            return;
        }

        NMLogTrace(@"Starting worker thread for queue 0x%p (%d operations in queue)", self, [self.keyDict count]);
        __block NNInternalOperationWrapper *wrap;

        dispatch_sync(self.soul, ^{
            wrap = [self nextAvailableOperation];
            
            if (wrap) {
                NMLogTrace(@"Dequeued operation 0x%p for queue 0x%p (key: \"%@\")", wrap.operation, self, wrap.key);
            }
        });

        while (wrap) {
            if (!self.running) {
                Assert(!wrap);
                return;
            }

            NMLogDebug(@"Running operation 0x%p on queue 0x%p (key: \"%@\")", wrap.operation, self, wrap.key);
            [wrap.operation start];
            [wrap.operation waitUntilFinished];
            NMLogTrace(@"Finished running operation 0x%p on queue 0x%p (key: \"%@\")", wrap.operation, self, wrap.key);
            
            dispatch_sync(self.soul, ^{
                // In case the operation was re-added while another instance of it was running
                if ([self.keyDict objectForKey:wrap.key]) {
                    NMLogTrace(@"Cancelling late-duplicated operation 0x%p on queue 0x%p (key: \"%@\")", [[self.keyDict objectForKey:wrap.key] operation], self, wrap.key);
                    [self removeWrappedOperationWithKey:wrap.key];
                }
                
                if (![self.priorityQueue count]) {
                    NMLogTrace(@"Worker thread ran out of operations for queue 0x%p", self);
                    self.running = NO;
                }
                
                wrap = [self nextAvailableOperation];
            });
        }
    });
}

@end
