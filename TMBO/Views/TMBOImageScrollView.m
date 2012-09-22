//
//  TMBOImageScrollView.m
//  TMBO
//
//  Created by Scott Perry on 09/22/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOImageScrollView.h"

@implementation TMBOImageScrollView
@synthesize imageView;

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // center the image as it becomes smaller than the size of the screen
    CGSize bounds = self.bounds.size;
    CGRect frame = imageView.frame;
    
    // center horizontally
    if (frame.size.width < bounds.width)
        frame.origin.x = (bounds.width - frame.size.width) / 2;
    else
        frame.origin.x = 0;
    
    // center vertically
    if (frame.size.height < bounds.height)
        frame.origin.y = (bounds.height - frame.size.height) / 2;
    else
        frame.origin.y = 0;
    
    imageView.frame = frame;
}

@end
