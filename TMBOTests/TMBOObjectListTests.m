//
//  TMBOObjectListTests.m
//  TMBO
//
//  Created by Scott Perry on 10/09/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOObjectListTests.h"

#import "TMBOObjectList.h"

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
@end

static NSArray *testObjects = nil;

@implementation TMBOObjectListTests

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

// These test cases are IN ORDER! Fix them from top to bottom.

#pragma mark All edge cases for object additions

- (void)testSingleAddition;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *add = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    NSArray *equals = add;
    
    [ol addObjectsFromArray:add];
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToTopWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(2, 3)];
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 5)];
    
    [ol addObjectsFromArray:addFirst];
    [ol addObjectsFromArray:addSecond];
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToBottomWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    NSArray *addFirst = [testObjects subarrayWithRange:NSMakeRange(0, 3)];
    NSArray *addSecond = [testObjects subarrayWithRange:NSMakeRange(2, 3)];
    NSArray *equals = [testObjects subarrayWithRange:NSMakeRange(0, 5)];
    
    [ol addObjectsFromArray:addFirst];
    [ol addObjectsFromArray:addSecond];
    
    STAssertEqualObjects(ol.items, equals, @"");
}

- (void)testAddToTopWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];

    // add objects 4…7, 0…3
    // Should add range
    STFail(@"Not implemented");
}

- (void)testAddToBottomWithoutOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    // add objects 0…3, 4…7
    // Should add range
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    // add objects 0…3, 6…9, 3…6
    // Objects only
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithEarlyOverlap;
{
    TMBOObjectList *ol = [[TMBOObjectList alloc] init];
    
    // add objects 0…3, 7…10, 3…6
    // Should update range
    STFail(@"Not implemented");
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
    [ol addObjectsFromArray:addSecond];
    
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
    [ol addObjectsFromArray:addSecond];
    
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
    }
    for (NSUInteger index = [testObjects count] - 1; index > [testObjects count] / 2; index--) {
        [ol addObjectsFromArray:[testObjects subarrayWithRange:NSMakeRange(index - 1, 2)]];
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

@end
