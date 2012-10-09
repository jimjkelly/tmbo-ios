//
//  TMBORange.m
//  TMBO
//
//  Created by Scott Perry on 10/07/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBORange.h"

@implementation TMBORange
@synthesize first = _first;
@synthesize last = _last;

+ (TMBORange *)rangeWithFirst:(NSInteger)first last:(NSInteger)last;
{
    return [[self alloc] initWithFirst:first last:last];
}

- (id)initWithFirst:(NSInteger)first last:(NSInteger)last;
{
    Assert(first < last);

    self = [super init];
    if (!self) return nil;
    
    _first = first;
    _last = last;
    
    return self;
}

- (BOOL)isEqual:(id)object;
{
    if (![object isKindOfClass:[TMBORange class]]) return NO;
    
    TMBORange *other = (TMBORange *)object;
    return other.last == self.last && other.first == self.first;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"range:(%d, %d)", self.first, self.last];
}

@end
