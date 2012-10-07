//
//  TMBOImageListCell.m
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOUploadCell.h"

@implementation TMBOUploadCell
@synthesize thumbnailView;
@synthesize filenameView;
@synthesize uploaderView;
@synthesize commentsView;
@synthesize spinner;

#define kXPadding 4.0f

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews;
{
    CGSize cellSize = self.frame.size;
    CGRect frame, thumbFrame = [self.thumbnailView frame];
    
    // commentsView has height (as needed) and width (as needed) and anchors at (cellWidth - (commentsViewWidth + padding), cellHeight - (uploaderViewHeight + padding))
    UILabel *label = self.commentsView;
    CGSize size = [[label text] sizeWithFont:[label font]];

    frame.size = size;
    frame.size.height = 18.0f;
    frame.origin.x = cellSize.width - (frame.size.width + kXPadding);
    frame.origin.y = 23.0f;
    
    [label setFrame:frame];
    [label setContentMode:UIViewContentModeRedraw];
    
    // uploaderView has height (as needed) and width (cellWidth - xAnchor - commentsViewWidth - padding) and anchors at (thumbnailViewRightEdge + padding, cellHeight - (uploaderViewHeight + padding))
    label = self.uploaderView;
    size = [[label text] sizeWithFont:[label font]];

    frame.origin.x = thumbFrame.origin.x + thumbFrame.size.width + kXPadding;
    frame.origin.y = 23.0f;
    frame.size = size;
    frame.size.height = 18.0f;
    frame.size.width = MIN(cellSize.width - (frame.origin.x + [self.commentsView frame].size.width + kXPadding), frame.size.width);
    
    [label setFrame:frame];
    [label setContentMode:UIViewContentModeRedraw];
    
    // filenameView has height (as needed) and width (cellWidth - (xAnchor + 2 * padding)) and anchors at (thumbnailViewWidth + padding, padding)
    label = self.filenameView;
    size = [[label text] sizeWithFont:[label font]];

    frame.origin.x = thumbFrame.origin.x + thumbFrame.size.width + kXPadding;
    frame.origin.y = 3.0f;
    frame.size = size;
    frame.size.height = 20.0f;
    frame.size.width = MIN(cellSize.width - (frame.origin.x + 2.0f * kXPadding), frame.size.width);
    
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
    thumbFrame.size.width = 133.0f / 100.0f * self.frame.size.height;
    [self.thumbnailView setFrame:thumbFrame];
    [self.thumbnailView setImage:nil];
    [self.spinner startAnimating];
}

@end
