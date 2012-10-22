//
//  NNProgressCircleView.m
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
//  This code is based on TKProgressCircleView by tapku.com || http://github.com/devinross/tapkulibrary
//

#import "NNProgressCircleView.h"

#define CLAMP(min, act, max) MIN(MAX((min),(act)),(max))

#define AnimationTimer 0.015
#define AnimationIncrement 0.02

@interface NNProgressCircleView ()
@property (nonatomic, assign) float displayProgress;
@end

@implementation NNProgressCircleView

- (id) init;
{
	self = [self initWithFrame:CGRectZero];
	return self;
}

- (id) initWithFrame:(CGRect)frame;
{
	frame.size = CGSizeMake(37.0, 37.0);
	if(!(self = [super initWithFrame:frame])) return nil;
    
	self.backgroundColor = [UIColor clearColor];
	self.userInteractionEnabled = NO;
	self.opaque = NO;
	_progress = 0.0f;
	_displayProgress = 0.0f;
    
	return self;
}

- (void) drawRect:(CGRect)rect;
{
    // Match drawn dimensions to UIActivityIndicatorView
    rect.size.height -= 2.0;
    rect.size.width -= 2.0;

	CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat centerX = rect.size.width/2;
    CGFloat centerY = rect.size.height/2;
    CGRect innerRect = CGRectInset(rect, centerX / 2, centerY / 2);

    // Set up clipping
    CGContextAddEllipseInRect(context, rect);
    CGContextAddEllipseInRect(context, innerRect);
    CGContextEOClip(context);
    
    // Background layer
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.2f);
    CGContextEOFillPath(context);
    
    // Progress bar
    // Pretty endcaps on progress bar?
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextAddArc(context, centerX, centerY, centerX, M_PI/-2.0, ((M_PI*2.0) *_displayProgress) - M_PI/2.0, 0);
    CGContextAddLineToPoint(context, centerX, centerY);
    CGContextFillPath(context);
}

- (void) updateProgress;
{
	if(_displayProgress >= _progress) return;
    
    
	_displayProgress += AnimationIncrement;
	[self setNeedsDisplay];
    
	if(_displayProgress <= _progress){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
		[self performSelector:@selector(updateProgress) withObject:nil afterDelay:AnimationTimer];
	}
}

#pragma mark Setter Methods

- (void) setProgress:(float)p animated:(BOOL)animated;
{
	p = CLAMP(0.0f, p, 1.0f);
    
	if (animated) {
		_progress = p;
		[self updateProgress];
	} else {
		_progress = p;
		_displayProgress = _progress;
		[self setNeedsDisplay];
	}
}

- (void) setProgress:(float)p;
{
	[self setProgress:p animated:NO];
}

@end
