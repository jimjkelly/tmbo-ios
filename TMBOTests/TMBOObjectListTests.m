//
//  TMBOObjectListTests.m
//  TMBO
//
//  Created by Scott Perry on 10/09/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOObjectListTests.h"

#import "TMBOObjectList.h"
#import "TMBORange.h"

@interface TestObject : NSObject <TMBOObject>
@property (nonatomic, readonly) NSInteger objectid;
- (id)initWithID:(NSInteger)objectid;
@end

@implementation TestObject
@synthesize objectid = _objectid;
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

#pragma mark All edge cases for object additions

- (void)testSingleAddition;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *add = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    
    NSArray *equals = add;
    STAssertTrue([self sanityCheck:equals], @"BAD TEST: Equals doesn't make sense!");
    
    [ol addObjectsFromArray:add];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
    STAssertEqualObjects(ol.items, equals, @"");
}

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
    NSMutableArray *equals = [[NSMutableArray alloc] initWithCapacity:[addFirst count] + 1 + [addSecond count]];
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
    NSMutableArray *equals = [[NSMutableArray alloc] initWithCapacity:[addFirst count] + 1 + [addSecond count]];
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
    NSMutableArray *equals = [[NSMutableArray alloc] initWithCapacity:[addFirst count] + 1 + [addSecond count] + [addThird count]];
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
    
    // add objects 0…3, 8…11, 4…7
    // Should split range
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithLateOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    // add objects 0…3, 7…10, 4…7
    // Should split range, then remove lower range
    STFail(@"Not implemented");
}

#pragma mark Same tests again, but with a minimum range set

- (void)testPreexistingMinimumAddToTopWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(2, 3)];
    // equals needs trailing range
//    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 5)];
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
//    STAssertEqualObjects(ol.items, equals, @"");

    // Objects only, followed by range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToBottomWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(2, 3)];
    // equals needs trailing range
//    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 5)];
    
    [ol addObjectsFromArray:addFirst];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    [ol addObjectsFromArray:addSecond];
    STAssertTrue([self sanityCheck:[ol items]], @"");
    
//    STAssertEqualObjects(ol.items, equals, @"");

    // Objects only, followed by range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToTopWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    // add objects 4…7, 0…3
    // Should add range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToBottomWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    // add objects 0…3, 4…7
    // Should add range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    // add objects 0…3, 6…9, 3…6
    // Objects only, followed by range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithEarlyOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    // add objects 0…3, 7…10, 3…6
    // Should update range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    // add objects 0…3, 8…11, 4…7
    // Should split range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithLateOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(1);
    
    // add objects 0…3, 7…10, 4…7
    // Should split range, then remove lower range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddObjectsIncludingMinimum;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    ol.minimumID = @(2);
    
    // Objects only
    STFail(@"Not implemented");
}

#pragma mark Extra edge cases

- (void)testWastefulAdd;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    for (NSUInteger index = 0; index < [testObjects count] / 2; index++) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index, 2)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    for (NSUInteger index = [testObjects count] - 1; index > [testObjects count] / 2; index--) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index - 1, 2)]];
        STAssertTrue([self sanityCheck:[ol items]], @"");
    }
    
    STAssertEqualObjects(ol.items, testObjects, @"");
}

- (void)testBadRangeDay;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    // add objects 0…1, 2…3, 4…5, 6…7, …, and then coalesce with 1…2, 3…6, 7…8, 9…12, …
    // Objects only
    STFail(@"Not implemented");
}

#pragma mark Non-test methods

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
    for (int i = 1; i < [objects count] - 1; i++) {
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
