//
//  TMBOObjectListTests.m
//  TMBO
//
//  Created by Scott Perry on 10/09/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOObjectListTests.h"

#import "TMBOObjectList.h"
#import "TMBORange.h"

@interface TestObject : NSObject <TMBOObject>
@property (nonatomic, readonly) NSInteger objectid;
- (id)initWithID:(NSInteger)objectid;
@end

@implementation TestObject

- (id)initWithID:(NSInteger)objectid;
{
    self = [super init];
    if (!self) return nil;
    
    _objectid = objectid;
    
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"objectid:%d", [self objectid]];
}
@end

static NSArray *testObjects = nil;

@implementation TMBOObjectListTests

// These test cases are IN ORDER! Fix them from top to bottom.

#pragma mark - Basic tests

- (void)testSingleAddition;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *add = [testObjects subarrayWithRange:NSMakeRange(0, 1)];
    
    NSArray *equals = add;
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:add];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testOneAddition;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *add = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    
    NSArray *equals = add;
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:add];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

#pragma mark All edge cases for object additions

- (void)testAddToTopWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(0, 4)]; // 0…3
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(3, 4)];  // 3…6
    
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 7)];    // 0…6
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToBottomWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(3, 4)]; // 3…6
    
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 7)];    // 0…6
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToTopWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];

    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(4, 4)]; // 4…7
    
    // 0…3,3-4,4…7
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToBottomWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(4, 4)];  // 4…7
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(0, 4)]; // 0…3
    
    // 0…3,3-4,4…7
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addSecond];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 4…7
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-4,4…7
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToMiddleWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(6, 4)]; // 6…9
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(3, 4)];  // 3…6
    
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 10)];    // 0…9
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-6,6…9
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…9
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToMiddleWithEarlyOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(7, 4)]; // 7…10
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(3, 4)];  // 3…6
    
    // 0…6,6-7,7…10
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(0, 7)]]; // 0…6
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:7] objectid] last:[[testObjects objectAtIndex:6] objectid]]];
    [equals addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-7,7…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…6,6-7,7…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToMiddleWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(8, 4)]; // 8…11
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(4, 4)];  // 4…7
    
    // 0…3,3-4,4…7,7-8,8…11
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:addThird];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:8] objectid] last:[[testObjects objectAtIndex:7] objectid]]];
    [equals addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-8,8…11
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…3,3-4,4…7,7-8,8…11
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToMiddleWithLateOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(7, 4)]; // 7…10
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(4, 4)];  // 4…7
    
    // 0…3,3-4,4…10
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(4, 7)]]; // 4…10
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-7,7…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…3,3-4,4…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

#pragma mark Same tests again, but with a minimum range set

- (void)testPreexistingMinimumSingleAddition;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *add = [testObjects subarrayWithRange:NSMakeRange(0, 1)];
    
    NSMutableArray *equals = [NSMutableArray arrayWithArray:[testObjects subarrayWithRange:NSMakeRange(0, 1)]];    // 0,0-min
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:add];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToTopWithOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(0, 4)]; // 0…3
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(3, 4)];  // 3…6
    
    NSMutableArray *equals = [NSMutableArray arrayWithArray:[testObjects subarrayWithRange:NSMakeRange(0, 7)]];    // 0…6,6-min
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToBottomWithOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(3, 4)]; // 3…6
    
    NSMutableArray *equals = [NSMutableArray arrayWithArray:[testObjects subarrayWithRange:NSMakeRange(0, 7)]];    // 0…6,6-min
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToTopWithoutOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(4, 4)]; // 4…7
    
    // 0…3,3-4,4…7,7-min
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:addSecond];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToBottomWithoutOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(4, 4)];  // 4…7
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(0, 4)]; // 0…3
    
    // 0…3,3-4,4…7,7-min
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addSecond];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 4…7
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-4,4…7
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToMiddleWithOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(6, 4)]; // 6…9
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(3, 4)];  // 3…6
    
    // 0…9,9-min
    NSMutableArray *equals = [[testObjects subarrayWithRange:NSMakeRange(0, 10)] mutableCopy];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-6,6…9
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…9
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToMiddleWithEarlyOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(7, 4)]; // 7…10
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(3, 4)];  // 3…6
    
    // 0…6,6-7,7…10,10-min
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(0, 7)]]; // 0…6
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:7] objectid] last:[[testObjects objectAtIndex:6] objectid]]];
    [equals addObjectsFromArray:addSecond];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-7,7…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…6,6-7,7…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToMiddleWithoutOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(8, 4)]; // 8…11
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(4, 4)];  // 4…7
    
    // 0…3,3-4,4…7,7-8,8…11,11-min
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:addThird];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:8] objectid] last:[[testObjects objectAtIndex:7] objectid]]];
    [equals addObjectsFromArray:addSecond];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-8,8…11
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…3,3-4,4…7,7-8,8…11
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddToMiddleWithLateOverlap;
{
    NSInteger minimumID = [[testObjects lastObject] objectid] - 1;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(7, 4)]; // 7…10
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(4, 4)];  // 4…7
    
    // 0…3,3-4,4…10,10-min
    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:[[testObjects objectAtIndex:4] objectid] last:[[testObjects objectAtIndex:3] objectid]]];
    [equals addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(4, 7)]]; // 4…10
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];  // 0…3
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond]; // 0…3,3-7,7…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addThird];  // 0…3,3-4,4…10
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testPreexistingMinimumAddObjectsIncludingMinimum;
{
    NSInteger minimumID = [[testObjects lastObject] objectid];
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(3, [testObjects count] - 3)]; // 3…end
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, testObjects, @"");
}

#pragma mark Extra edge cases

- (void)testWastefulAdd;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    for (NSUInteger index = 0; index < [testObjects count] / 2; index++) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 3)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    for (NSUInteger index = [testObjects count] - 1; index > [testObjects count] / 2; index--) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index - 2, 3)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    
    STAssertEqualObjects(ol.items, testObjects, @"");
}

- (void)testBadRangeDay;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    for (NSUInteger index = 0; index < [testObjects count]; index += 2) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 2)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    for (NSUInteger index = 1; index < [testObjects count] - 1; index += 2) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 2)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    
    STAssertEqualObjects(ol.items, testObjects, @"");
}

- (void)testBadSingleRangeDay;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    for (NSUInteger index = 0; index < [testObjects count]; index++) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 1)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    for (NSUInteger index = 0; index < [testObjects count]; index += 2) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 2)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    for (NSUInteger index = 1; index < [testObjects count] - 1; index += 2) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 2)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    
    STAssertEqualObjects(ol.items, testObjects, @"");
}

- (void)testAddBelowMinimum;
{
    NSInteger minimumObject = 7;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@([[testObjects objectAtIndex:minimumObject] objectid])];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(3, [testObjects count] - 3)]; // 3…end
    
    // 0…7
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, minimumObject + 1)];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToMinimumThenBelow;
{
    NSInteger minimumObject = 7;
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@([[testObjects objectAtIndex:minimumObject] objectid])];
    
    NSUInteger breakpoint = 3;
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, breakpoint + 1)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(breakpoint, minimumObject - (breakpoint - 1))]; // 3…7
    NSArray *addThird = [testObjects subarrayWithRange:NSMakeRange(breakpoint, [testObjects count] - breakpoint)];
    NSArray *addFourth = [testObjects subarrayWithRange:NSMakeRange(minimumObject + 1, [testObjects count] - (minimumObject + 1))];
    
    // 0…7
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, minimumObject + 1)];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    // Add a set of invalid objects
    NSArray *firstState = [ol items];
    [ol addObjectsFromArray:addFourth];
    STAssertEqualObjects([ol items], firstState, @"");
    
    // Add bottom-overlapping including minimum
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, equals, @"");

    // Add range overlapping minimum
    [ol addObjectsFromArray:addThird];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, equals, @"");

    // Add range below minimum
    [ol addObjectsFromArray:addFourth];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testSettingValidMinimumLater;
{
    NSInteger minimumID = [[testObjects lastObject] objectid];
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(3, [testObjects count] - 3)]; // 3…end
    NSMutableArray *equals;
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");

    equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    [ol setMinimumID:@(minimumID)];
    STAssertEqualObjects([ol items], equals, @"");

    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, testObjects, @"");
}

- (void)testSettingBorderlineMinimumLater;
{
    NSInteger minimumID = [[testObjects lastObject] objectid];
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = testObjects;
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, testObjects, @"");

    [ol setMinimumID:@(minimumID)];
    STAssertEqualObjects(ol.items, testObjects, @"");
}

- (void)testSetInvalidMinimumMulti;
{
    NSInteger minimumID = [[testObjects lastObject] objectid];
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = testObjects;
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, testObjects, @"");
    
    [ol setMinimumID:@(minimumID)];
    STAssertEqualObjects(ol.items, testObjects, @"");
    
    // Otherwise valid minimum
    STAssertThrows([ol setMinimumID:@(1)], @"");

    // Outright invalid minimum
    STAssertThrows([ol setMinimumID:@([[testObjects objectAtIndex:0] objectid])], @"");
}

- (void)testSetInvalidMinimum;
{
    NSInteger minimumID = [[testObjects objectAtIndex:0] objectid];
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = testObjects;
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, testObjects, @"");
    
    STAssertThrows([ol setMinimumID:@(minimumID)], @"");
}

- (void)testSetMinimumMulti;
{
    NSInteger minimumID = [[testObjects lastObject] objectid];
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol setMinimumID:@(minimumID)];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 4)];  // 0…3
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(3, [testObjects count] - 3)]; // 3…end

    NSMutableArray *equals = [[NSMutableArray alloc] init];
    [equals addObjectsFromArray:addFirst];
    [equals addObject:[TMBORange rangeWithFirst:minimumID last:[[equals lastObject] objectid]]];
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects([ol items], equals, @"");
    
    [ol setMinimumID:@(minimumID)];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects([ol items], equals, @"");
    
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, testObjects, @"");

    [ol setMinimumID:@(minimumID)];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    STAssertEqualObjects(ol.items, testObjects, @"");
}

#pragma mark Accessor tests

- (void)testAccessAfter;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol addObjectsFromArray:testObjects];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects([ol objectAfterObject:[testObjects objectAtIndex:1]], [testObjects objectAtIndex:0], @"");
}

- (void)testAccessBefore;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol addObjectsFromArray:testObjects];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects([ol objectBeforeObject:[testObjects objectAtIndex:([testObjects count] - 2)]], [testObjects objectAtIndex:([testObjects count] - 1)], @"");
}

- (void)testAccessAfterEnd;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol addObjectsFromArray:testObjects];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertNil([ol objectAfterObject:[testObjects objectAtIndex:0]], @"");
}

- (void)testAccessBeforeBeginning;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    [ol addObjectsFromArray:testObjects];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertNil([ol objectBeforeObject:[testObjects objectAtIndex:([testObjects count] - 1)]], @"");
}

- (void)testAccessInvalidAfter;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    STAssertNil([ol objectAfterObject:[testObjects objectAtIndex:1]], @"");
}

- (void)testAccessInvalidBefore;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    STAssertNil([ol objectBeforeObject:[ol objectAfterObject:[testObjects objectAtIndex:([testObjects count] - 2)]]], @"");
}

#pragma mark - Non-test methods

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#define to(x) [[TestObject alloc] initWithID:(x)]
        testObjects = [@[ to(2), to(3), to(5), to(7), to(11), to(13), to(17), to(19), to(23), to(29), to(31), to(37), to(41), to(43), to(47), to(53), to(59), to(61), to(67), to(71), to(73), to(79), to(83), to(89), to(97), to(101), to(103), to(107), to(109), to(113), to(127), to(131), to(137), to(139), to(149), to(151), to(157), to(163), to(167), to(173) ] sortedArrayUsingComparator:^(id a, id b) {
            Assert([[a class] conformsToProtocol:@protocol(TMBOObject)]);
            Assert([[b class] conformsToProtocol:@protocol(TMBOObject)]);
            Assert([a objectid] != [b objectid]);
            // Reverse sort: lower indexes are higher uploads
            return [@([b objectid]) compare:@([a objectid])];
        }];
#undef to
    });
}

- (BOOL)sanityCheck:(NSArray *)objects;
{
    for (int i = 1; i < (int)[objects count] - 1; i++) {
        id item = [objects objectAtIndex:i];
        id higher = [objects objectAtIndex:i - 1];
        id lower = [objects objectAtIndex:i + 1];
        
        if ([[item class] conformsToProtocol:@protocol(TMBOObject)]) {
            if ([[higher  class] conformsToProtocol:@protocol(TMBOObject)]) {
                if ([higher objectid] <= [item objectid]) return NO;
            } else {
                if (![higher isKindOfClass:[TMBORange class]]) return NO;
                if (((TMBORange *)higher).first != [item objectid]) return NO;
            }
            
            if ([[lower class] conformsToProtocol:@protocol(TMBOObject)]) {
                if ([lower objectid] >= [item objectid]) return NO;
            } else {
                if (![lower isKindOfClass:[TMBORange class]]) return NO;
                if (((TMBORange *)lower).last != [item objectid]) return NO;
            }
        } else if ([item isKindOfClass:[TMBORange class]]) {
            if (((TMBORange *)item).last == ((TMBORange *)item).first) return NO;
            if (![[higher class] conformsToProtocol:@protocol(TMBOObject)]) return NO;
            if (![[lower class] conformsToProtocol:@protocol(TMBOObject)]) return NO;
            if ([higher objectid] != ((TMBORange *)item).last) return NO;
            if ([lower objectid] != ((TMBORange *)item).first) return NO;
        }
    }
    
    return YES;
}

@end
