//
//  TMBOImageListCell.m
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOImageListCell.h"

@implementation TMBOImageListCell
@synthesize thumbnailView;
@synthesize filenameView;
@synthesize uploaderView;
@synthesize commentsView;
@synthesize votesView;
@synthesize spinner;

#define kXPadding 4.0

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews;
{
    CGSize cellSize = self.frame.size;
    CGRect frame, thumbFrame = [self.thumbnailView frame];
    
    // votesView has height (as needed) and width (as needed) and anchors at (cellWidth - (votesViewWidth + padding), cellHeight - (votesViewHeight + padding)
    UILabel *label = self.votesView;
    CGSize size = [[label text] sizeWithFont:[label font]];
    
    frame.size = size;
    frame.size.height = 18.0;
    frame.origin.x = cellSize.width - (frame.size.width + kXPadding);
    frame.origin.y = 23.0;
    
    [label setFrame:frame];
    [label setContentMode:UIViewContentModeRedraw];

    // commentsView has height (as needed) and width (as needed) and anchors at (cellWidth - (commentsViewWidth + padding), padding)
    label = self.commentsView;
    size = [[label text] sizeWithFont:[label font]];

    frame.size = size;
    frame.size.height = 18.0;
    frame.origin.x = cellSize.width - (frame.size.width + kXPadding);
    frame.origin.y = 4.0;
    
    [label setFrame:frame];
    [label setContentMode:UIViewContentModeRedraw];
    
    // uploaderView has height (as needed) and width (cellWidth - xAnchor - votesViewWidth - padding) and anchors at (thumbnailViewRightEdge + padding, cellHeight - (uploaderViewHeight + padding)
    label = self.uploaderView;
    size = [[label text] sizeWithFont:[label font]];

    frame.origin.x = thumbFrame.origin.x + thumbFrame.size.width + kXPadding;
    frame.origin.y = 23.0;
    frame.size = size;
    frame.size.height = 18.0;
    frame.size.width = MIN(cellSize.width - (frame.origin.x + [self.votesView frame].size.width + kXPadding), frame.size.width);
    
    [label setFrame:frame];
    [label setContentMode:UIViewContentModeRedraw];
    
    // filenameView has height (as needed) and width (xAnchor - commentsViewXAnchor - padding) and anchors at (thumbnailViewWidth + padding, padding)
    label = self.filenameView;
    size = [[label text] sizeWithFont:[label font]];

    frame.origin.x = thumbFrame.origin.x + thumbFrame.size.width + kXPadding;
    frame.origin.y = 3.0;
    frame.size = size;
    frame.size.height = 20.0;
    frame.size.width = MIN(cellSize.width - (frame.origin.x + [self.commentsView frame].size.width + 5.0), frame.size.width);
    
    [label setFrame:frame];
    [label setContentMode:UIViewContentModeRedraw];
    
    // selectedBackgroundView also needs to be updated in case of rotation
    CGRect backgroundViewFrame = [self frame];
    backgroundViewFrame.origin = CGPointZero;
    [[self selectedBackgroundView] setFrame:backgroundViewFrame];
}

- (void)prepareForReuse;
{
    CGRect thumbFrame;
    thumbFrame.origin = CGPointZero;
    thumbFrame.size.height = self.frame.size.height;
    thumbFrame.size.width = 133 / 100 * self.frame.size.height;
    [self.thumbnailView setFrame:thumbFrame];
    [self.thumbnailView setImage:nil];
    [self.spinner startAnimating];
}

@end
