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
        testObjects = @[ to(2), to(3), to(5), to(7), to(11), to(13), to(17), to(19), to(23), to(29), to(31), to(37), to(41), to(43), to(47), to(53), to(59), to(61), to(67), to(71), to(73), to(79), to(83), to(89), to(97), to(101), to(103), to(107), to(109), to(113), to(127), to(131), to(137), to(139), to(149), to(151), to(157), to(163), to(167), to(173) ];
        #undef to
    });
}

- (void)testAddToTopWithoutOverlap;
{
    // Should add range
    STFail(@"Not implemented");
}

- (void)testAddToTopWithOverlap;
{
    // Objects only
    STFail(@"Not implemented");
}

- (void)testAddToBottomWithoutOverlap;
{
    // Should add range
    STFail(@"Not implemented");
}

- (void)testAddToBottomWithOverlap;
{
    // Objects only
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithoutOverlap;
{
    // Should split range
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithEarlyOverlap;
{
    // Should update range
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithLateOverlap;
{
    // Should split range, then remove lower range
    STFail(@"Not implemented");
}

- (void)testAddToMiddleWithOverlap;
{
    // Objects only
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToTopWithoutOverlap;
{
    // Should add range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToTopWithOverlap;
{
    // Objects only, followed by range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToBottomWithoutOverlap;
{
    // Should add range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToBottomWithOverlap;
{
    // Objects only, followed by range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithoutOverlap;
{
    // Should split range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithEarlyOverlap;
{
    // Should update range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithLateOverlap;
{
    // Should split range, then remove lower range
    STFail(@"Not implemented");
}

- (void)testPreexistingMinimumAddToMiddleWithOverlap;
{
    // Objects only, followed by range
    STFail(@"Not implemented");
}

@end
