//
//  TMBOImageScrollView.m
//  TMBO
//
//  Created by Scott Perry on 09/22/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOImageScrollView.h"

@implementation TMBOImageScrollView
@synthesize contentView = _scrollableContentView;

- (void)setContentView:(UIView *)contentView;
{
    [self addSubview:contentView];
    [self setContentSize:contentView.frame.size];
    _scrollableContentView = contentView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize bounds = self.bounds.size;
    CGRect frame = self.contentView.frame;
    
    // center the image as it becomes smaller than the size of the screen. If it is larger, set the origin to (0,0).
    frame.origin.x = MAX(((bounds.width - frame.size.width) / 2), 0);
    frame.origin.y = MAX(((bounds.height - frame.size.height) / 2), 0);

    [self.contentView setFrame:frame];
}

@end
