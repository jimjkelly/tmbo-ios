//
//  TMBOObjectList.m
//  TMBO
//
//  Created by Scott Perry on 10/08/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOObjectList.h"

#import "TMBORange.h"

static NSComparator kObjectComparator = ^(id a, id b) {
    Assert([[a class] conformsToProtocol:@protocol(TMBOObject)]);
    Assert([[b class] conformsToProtocol:@protocol(TMBOObject)]);
    Assert([a objectid] != [b objectid]);
    // Reverse sort: lower indexes are higher uploads
    return [@([b objectid]) compare:@([a objectid])];
};

@interface TMBOObjectList ()
@property (nonatomic, strong) NSMutableArray *list;
@end

@implementation TMBOObjectList
@synthesize list = _list;

- (id)init;
{
    self = [super init];
    if (!self) return nil;
    
    _list = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)destroy;
{
    if (!self.removedObject) return;
    
    for (id object in self.list) {
        if (![[object  class] conformsToProtocol:@protocol(TMBOObject)]) continue;
        self.removedObject(object);
    }

    [self.list removeAllObjects];
}

- (void)addObjectsFromArray:(NSArray *)immutableObjects;
{
    if ([immutableObjects count] < 2) return;
    NSMutableArray *objects = [immutableObjects mutableCopy];
    [objects sortUsingComparator:kObjectComparator];
    
    if (![self.list count]) {
        // First population of table
        [self _addItemsFromArray:objects until:NSIntegerMin insertionIndex:NULL];
    } else {
        // Uploads newer than anything else in self.items
        NSUInteger insertionIndex = 0;
        NSInteger lastInserted = NSIntegerMin;
        
        NSInteger tableTop;
        if ([[self.list objectAtIndex:0] isKindOfClass:[TMBORange class]]) {
            // A TMBORange should only be at the top of the list if it is the only item in the list
            Assert([self.list count] == 1);
            // tableTop adding is exclusive, include the minimum value as a possible insertion
            tableTop = ((TMBORange *)[self.list objectAtIndex:0]).first - 1;
        } else {
            Assert([[[self.list objectAtIndex:0] class] conformsToProtocol:@protocol(TMBOObject)]);
            tableTop = [[self.list objectAtIndex:0] objectid];
        }
        
        lastInserted = [self _addItemsFromArray:objects until:tableTop insertionIndex:&insertionIndex];
        
        if (insertionIndex && [[self.list objectAtIndex:insertionIndex] isKindOfClass:[TMBORange class]]) {
            // We inserted *anything* and previously had a range leading the list (indicating a previously-empty list, other than the range)
            Assert([[[self.list objectAtIndex:(insertionIndex - 1)] class] conformsToProtocol:@protocol(TMBOObject)]);
            Assert(lastInserted >= ((TMBORange *)[self.list objectAtIndex:insertionIndex]).first);
            
            if (lastInserted == ((TMBORange *)[self.list objectAtIndex:insertionIndex]).first) {
                // Satisfied lower end of range, remove range.
                [self.list removeObjectAtIndex:insertionIndex];
            } else {
                // Update range
                ((TMBORange *)[self.list objectAtIndex:insertionIndex]).last = lastInserted;
            }
        } else if (![objects count]) {
            // Ran out of uploads before hitting pre-existing top of list, add a range
            Assert([[[self.list objectAtIndex:(insertionIndex - 1)] class] conformsToProtocol:@protocol(TMBOObject)]);
            Assert([[[self.list objectAtIndex:insertionIndex] class] conformsToProtocol:@protocol(TMBOObject)]);
            NotTested();
            
            NSUInteger first = [(id<TMBOObject>)[self.list objectAtIndex:insertionIndex] objectid];
            NSUInteger last = [(id<TMBOObject>)[self.list objectAtIndex:(insertionIndex - 1)] objectid];
            [self.list insertObject:[TMBORange rangeWithFirst:first last:last] atIndex:insertionIndex++];
        }
        
        for (; insertionIndex < [self.list count] && [objects count]; insertionIndex++) {
            // Add new uploads to the ranged gaps of the list
            if (![[self.list objectAtIndex:insertionIndex] isKindOfClass:[TMBORange class]]) continue;
            TMBORange *range = [self.items objectAtIndex:insertionIndex];
            
            // No objects fit inside this range.
            if ([(id <TMBOObject>)[objects objectAtIndex:0] objectid] <= range.first) continue;
            
            // Remove objects above the range
            NSUInteger lastRemoved = [self _removeItemsFromArray:objects until:(range.last + 1)];
            if (![objects count]) break;
            
            // No objects were removed, no overlap with the higher side of the insertion range!
            if (lastRemoved == NSIntegerMin) {
                NotTested();
                // It shouldn't be possible for this to happen when loading at the bottom of the table
                Assert(!self.minimumID || range.first > [self.minimumID integerValue]);
                
                [self.list insertObject:[TMBORange rangeWithFirst:range.first last:[(id <TMBOObject>)[objects objectAtIndex:0] objectid]] atIndex:insertionIndex++];
            }
            
            // Insert objects in range
            lastRemoved = [self _addItemsFromArray:objects until:range.first insertionIndex:&insertionIndex];
            
            if ([objects count] && [(id <TMBOObject>)[objects objectAtIndex:0] objectid] == range.first) {
                // Objects satisfied entireity of range, remove range.
                [self.list removeObjectAtIndex:insertionIndex];
            } else {
                Assert(lastRemoved != NSIntegerMin);
                range.last = lastRemoved;
            }
        }
    }
    
#ifdef DEBUG
    for (int i = 1; i < [self.list count] - 1; i++) {
        id item = [self.list objectAtIndex:i];
        id higher = [self.list objectAtIndex:i - 1];
        id lower = [self.list objectAtIndex:i + 1];
        
        if ([[item class] conformsToProtocol:@protocol(TMBOObject)]) {
            if ([[higher  class] conformsToProtocol:@protocol(TMBOObject)]) {
                Assert([higher objectid] > [item objectid]);
            } else {
                Assert([higher isKindOfClass:[TMBORange class]]);
                Assert(((TMBORange *)higher).first == [item objectid]);
            }
            
            if ([[lower class] conformsToProtocol:@protocol(TMBOObject)]) {
                Assert([lower objectid] < [item objectid]);
            } else {
                Assert([lower isKindOfClass:[TMBORange class]]);
                Assert(((TMBORange *)lower).last == [item objectid]);
            }
        } else if ([item isKindOfClass:[TMBORange class]]) {
            Assert([[higher class] conformsToProtocol:@protocol(TMBOObject)]);
            Assert([[lower class] conformsToProtocol:@protocol(TMBOObject)]);
            Assert([higher objectid] == ((TMBORange *)item).last);
            Assert([lower objectid] == ((TMBORange *)item).first);
        }
    }
#endif
}

#pragma mark - Synthetic properties
@dynamic minimumID;
@dynamic items;

- (NSNumber *)minimumID;
{
    if ([self.list count] && [[self.list lastObject] isKindOfClass:[TMBORange class]]) {
        return @(((TMBORange *)[self.list lastObject]).first);
    }
    return nil;
}

- (void)setMinimumID:(NSNumber *)minimumID;
{
    // XXX: for now, you can only change the minimum ID once
    Assert(!self.minimumID || [minimumID isEqualToNumber:self.minimumID]);
    
    TMBORange *range;
    if ([self.list count]) {
        Assert([[[self.list lastObject] class] conformsToProtocol:@protocol(TMBOObject)]);
        range = [TMBORange rangeWithFirst:[minimumID integerValue] last:[(id<TMBOObject>)[self.list lastObject] objectid]];
    } else {
        range = [TMBORange rangeWithFirst:[minimumID integerValue] last:NSIntegerMax];
    }

    [self.list insertObject:range atIndex:[self.list count]];
}

- (NSArray *)items;
{
    return [self.list copy];
}

#pragma mark - Private methods

// returns: objectid of last element removed, until is EXCLUSIVE
- (NSInteger)_removeItemsFromArray:(NSMutableArray *)objects until:(NSInteger)objectid;
{
    NSInteger last = NSIntegerMin;
    
    if (![objects count]) return last;
    
    while ([objects count] && [(id<TMBOObject>)[objects objectAtIndex:0] objectid] < objectid) {
        last = [(id<TMBOObject>)[objects objectAtIndex:0] objectid];
        [objects removeObjectAtIndex:0];
    }
    
    return last;
}

// returns: objectid of last element added, until is EXCLUSIVE
- (NSInteger)_addItemsFromArray:(NSMutableArray *)objects until:(NSInteger)objectid insertionIndex:(NSUInteger *)index;
{
    NSUInteger insertionIndex = index ? *index : 0;
    NSInteger last = NSIntegerMin;
    
    while ([objects count] && [(id<TMBOObject>)[objects objectAtIndex:0] objectid] > objectid) {
        id<TMBOObject> object = [objects objectAtIndex:0];
        Assert([[object  class] conformsToProtocol:@protocol(TMBOObject)]);
        last = [object objectid];

        // Remove from insertion array and insert into collection
        [objects removeObjectAtIndex:0];
        [self.list insertObject:object atIndex:insertionIndex++];

        if (self.addedObject) self.addedObject(object);
    }
    
    if (index) *index = insertionIndex;
    
    return last;
}

@end
