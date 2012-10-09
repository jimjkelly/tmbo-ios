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
    
    // TODO: Assert first object objectid < NSIntegerMax
    // TODO: Assert last object objectid > NSIntegerMin

#define arrayObjectAtIndexAsObject(arr, x) ((id<TMBOObject>)[(arr) objectAtIndex:(x)])
#define listObjectAtIndexIsObject(x) ((BOOL)([[[self.list objectAtIndex:(x)] class] conformsToProtocol:@protocol(TMBOObject)]))
#define listObjectAtIndexIsRange(x) ((BOOL)([[self.list objectAtIndex:(x)] isKindOfClass:[TMBORange class]]))
#define listObjectAtIndexAsObject(x) arrayObjectAtIndexAsObject(self.list, (x))
#define listObjectAtIndexAsRange(x) ((TMBORange *)[self.list objectAtIndex:(x)])
#define topObject() arrayObjectAtIndexAsObject(objects, 0)
    
    NSUInteger insertionIndex = 0;
    NSInteger lastAdded = NSIntegerMin;
    NSInteger startAfter = NSIntegerMax;
    NSInteger max;
    {   // Initial state:
        // Add until end of known universe
        max = NSIntegerMin;
        if ([self.list count]) {
            if (listObjectAtIndexIsObject(0)) {
                // Add until reaching id of highest object
                max = [listObjectAtIndexAsObject(0) objectid];
            }
            if (listObjectAtIndexIsRange(0)) {
                // Add until reaching bottom of range. Range should only be object 0 if it is the only object in existence.
                TMBORange *range = listObjectAtIndexAsRange(0);
                Assert(range.last == NSIntegerMax);
                Assert([self.list count] == 1);
                max = range.first;
            }
        }
    }
    
    do {
        lastAdded = [self _addItemsFromArray:objects until:max insertionIndex:&insertionIndex];
        
        // Safe point: inserting into end of list
        if ([self.list count] <= insertionIndex) {
            Assert(insertionIndex == [self.list count]);
            Assert(![objects count]);
            return;
        }
        
        if (listObjectAtIndexIsRange(insertionIndex)) {
            // Inserting ahead of a range, update or remove range as appropriate
            if ([objects count] && [topObject() objectid] == max) {
                Assert(listObjectAtIndexAsRange(insertionIndex).first == max);
                [self.list removeObjectAtIndex:insertionIndex];
            } else {
                // If the range was not completed, there can not be any more objects left
                Assert(![objects count]);
                Assert(insertionIndex);
                listObjectAtIndexAsRange(insertionIndex).last = [listObjectAtIndexAsObject(insertionIndex - 1) objectid];
            }
        } else if (listObjectAtIndexIsObject(insertionIndex) && ![objects count]) {
            // No overlap, ran out of objects to insert, insert a new range
            TMBORange *range = [TMBORange rangeWithFirst:[listObjectAtIndexAsObject(insertionIndex) objectid] last:lastAdded];
            [self.list insertObject:range atIndex:insertionIndex++];
        }
        
        // Safe point: list is stable and no more objects to add
        if (![objects count]) return;
        
        max = NSIntegerMin;
        startAfter = NSIntegerMin;
        if (listObjectAtIndexIsObject([self.list count] - 1)) {
            startAfter = [listObjectAtIndexAsObject([self.list count] - 1) objectid];
        }
        while (++insertionIndex < [self.list count]) {
            // Add into existing ranges
            if (listObjectAtIndexIsObject(insertionIndex)) continue;
            Assert(listObjectAtIndexIsRange(insertionIndex));
            
            // Nothing to contribute for this range
            if ([topObject() objectid] <= listObjectAtIndexAsRange(insertionIndex).first) continue;
            
            max = listObjectAtIndexAsRange(insertionIndex).first;
            startAfter = listObjectAtIndexAsRange(insertionIndex).last;
            break;
        }
        // Either we've found a range, or we're inserting at the end of the list (or both)
        Assert(insertionIndex == [self.list count] || listObjectAtIndexIsRange(insertionIndex));
        // Something must have set startAfter, either the trailing range or the last object of the list.
        Assert(startAfter > NSIntegerMin);
        
        // Remove duplicates. Note `until` is exclusive, so decrement to capture the last valid object id
        {
            NSInteger lastPopped = [self _removeItemsFromArray:objects until:(startAfter - 1)];
            
            // Safe point: list is stable and no more objects to add
            if (![objects count]) return;
            
            if (lastPopped < startAfter) {
                // No overlap at top of range, insert a new range
                TMBORange *range = [TMBORange rangeWithFirst:[topObject() objectid] last:startAfter];
                [self.list insertObject:range atIndex:insertionIndex++];
            }
        }
        
    } while([objects count]);
    
#undef listObjectAtIndexIsObject
#undef listObjectAtIndexIsRange
#undef listObjectAtIndexAsObject
#undef listObjectAtIndexAsRange
#undef arrayObjectAtIndexAsObject
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
    
    while ([objects count] && [(id<TMBOObject>)[objects objectAtIndex:0] objectid] > objectid) {
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
