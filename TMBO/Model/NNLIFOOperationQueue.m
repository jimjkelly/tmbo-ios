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

@end

@implementation NNLIFOOperationQueue
@synthesize suspended = _suspended;

- (id)init;
{
    self = [super init];
    BailUnless(self, nil);
    
    _priorityQueue = [[NSMutableArray alloc] init];
    _keyDict = [[NSMutableDictionary alloc] init];
    _running = NO;
    _seq = 0;
    
    return self;
}

- (void)addOperation:(NSOperation *)operation forKey:(id<NSCopying>)key;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self) {
            NNInternalOperationWrapper *wrap = [self.keyDict objectForKey:key];
            if (wrap) {
                [self cancelWrappedOperationWithKey:wrap.key];
                wrap = nil;
            }
            
            wrap = [[NNInternalOperationWrapper alloc] init];
            wrap.operation = operation;
            wrap.key = key;
            wrap.seq = self.seq++;
            [self.priorityQueue addObject:wrap];
            [self.keyDict setObject:wrap forKey:key];
            [self worker];
        }
    });
}

- (void)cancelAllOperations;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self) {
            while ([self.priorityQueue count]) {
                [self cancelWrappedOperationWithKey:((NNInternalOperationWrapper *)[self.priorityQueue lastObject]).key];
            }
        }
    });
}

- (void)setSuspended:(BOOL)suspended;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self) {
            if (!suspended) {
                [self worker];
            }
            _suspended = suspended;
        }
    });
}

#pragma mark Properties

- (NSArray *)operations;
{
    return [self.priorityQueue copy];
}

#pragma mark Private

- (void)cancelWrappedOperationWithKey:(id<NSCopying>)key;
{
    NNInternalOperationWrapper *wrap;
    
    @synchronized(self) {
        wrap = [self.keyDict objectForKey:key];
        if (!wrap) return;
        
        NSUInteger index = [self.priorityQueue indexOfObject:wrap inSortedRange:NSMakeRange(0, [self.priorityQueue count]) options:NSBinarySearchingFirstEqual usingComparator:priorityQueueComparator];
        Assert(index != NSNotFound);
        
        [self.keyDict removeObjectForKey:wrap.key];
        // NSArray is still a list inside, so removing from the middle can be expensive. Mitigate this by replacing operations with tombstone objects.
        [self.priorityQueue replaceObjectAtIndex:index withObject:@(wrap.seq)];
    }

    [wrap.operation cancel];
    [wrap.operation start];
}

- (void)worker;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self) {
            if (self.suspended) return;
            if (self.running) return;
            if (![self.priorityQueue count]) return;
            self.running = YES;
        }
        
        while ([self.priorityQueue count]) {
            NNInternalOperationWrapper *wrap;
            
            @synchronized(self) {
                // Skip tombstones
                if ([[self.priorityQueue lastObject] isKindOfClass:[NSNumber class]]) {
                    [self.priorityQueue removeLastObject];
                    continue;
                }
                if (self.suspended) return;
                
                wrap = [self.priorityQueue lastObject];
                [self.priorityQueue removeLastObject];
                
                Check([wrap.operation isReady]);
                if(![wrap.operation isReady]) {
                    // Bad behaviour is rewarded by being inserted at the very end of the queue
                    [self.priorityQueue insertObject:wrap atIndex:0];
                    continue;
                }
                
                Assert([self.keyDict objectForKey:wrap.key]);
                [self.keyDict removeObjectForKey:wrap.key];
            }
            
            [wrap.operation start];
            [wrap.operation waitUntilFinished];
            
            @synchronized(self) {
                // In case the operation was re-added while another instance of it was running
                if ([self.keyDict objectForKey:wrap.key]) {
                    [self cancelWrappedOperationWithKey:wrap.key];
                }
                
                if (![self.priorityQueue count]) {
                    self.running = NO;
                    return;
                }
            }
        }
    });
}

@end
