//
//  NNProgressCircleViewTests.m
//  TMBO
//
//  Created by Scott Perry on 10/21/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNProgressCircleViewTests.h"

#import "NNProgressCircleView.h"

@implementation NNProgressCircleViewTests
- (BOOL)shouldRunOnMainThread { return YES; }

- (void)testNNProgressCircleViewZero {
    NNProgressCircleView *circle = [[NNProgressCircleView alloc] init];
    UIView *view = [self prepareViewWithCircle:circle];
    circle.progress = 0.0f;
    
    GHVerifyView(view);
}

- (void)testNNProgressCircleViewOneThird {
    NNProgressCircleView *circle = [[NNProgressCircleView alloc] init];
    UIView *view = [self prepareViewWithCircle:circle];
    circle.progress = 0.333333333f;
    
    GHVerifyView(view);
}

- (void)testNNProgressCircleViewThreeQuarters {
    NNProgressCircleView *circle = [[NNProgressCircleView alloc] init];
    UIView *view = [self prepareViewWithCircle:circle];
    circle.progress = 0.75f;
    
    GHVerifyView(view);
}

- (void)testNNProgressCircleViewFinished {
    NNProgressCircleView *circle = [[NNProgressCircleView alloc] init];
    UIView *view = [self prepareViewWithCircle:circle];
    circle.progress = 1.0f;
    
    GHVerifyView(view);
}

- (UIView *)prepareViewWithCircle:(NNProgressCircleView *)circle;
{
    CGRect superFrame = CGRectMake(0.0f, 0.0f, 47.0f, 47.0f);
    CGRect subFrame = CGRectInset(superFrame, 5.0f, 5.0f);
    UIView *view = [[UIView alloc] initWithFrame:superFrame];
    view.backgroundColor = [UIColor blackColor];
    [view addSubview:circle];
    circle.frame = subFrame;
    return view;
}

@end
