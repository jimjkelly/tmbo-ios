//
//  TMBORange.m
//  TMBO
//
//  Created by Scott Perry on 10/07/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBORange.h"

@implementation TMBORange
@synthesize first = _first;
@synthesize last = _last;

- (id)initWithFirst:(NSInteger)first last:(NSInteger)last;
{
    self = [super init];
    if (!self) return nil;
    
    _first = first;
    _last = last;
    
    return self;
}

@end
