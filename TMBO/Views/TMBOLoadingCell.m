//
//  TMBOLoadingCell.m
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

#import "TMBOLoadingCell.h"

NSString * const kTMBOLoadingCellName = @"TMBOLoadingCell";

@implementation TMBOLoadingCell

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    [self _init];
    
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;
    
    [self _init];
    
    return self;
}

- (void)_init;
{
    // Cell does not highlight on selection, but it does change state (see: -setSelected:animated:)
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
    [self.spinner startAnimating];
}

#pragma mark Display modes
- (void)setMode:(TMBOLoadingCellMode)mode;
{
    switch (mode) {
        case TMBOLoadingCellModeDefault:
            [self defaultMode];
            break;
        case TMBOLoadingCellModeLoading:
            [self loadingMode];
            break;
        case TMBOLoadingCellModeError:
            [self errorMode];
            break;
    }
}

// TODO: animate between modes
- (void)loadingMode;
{
    [self _styleCell];

    self.spinner.hidden = NO;
    [self.spinner startAnimating];
}

- (void)defaultMode;
{
    [self _styleCell];
    
    self.spinner.hidden = YES;
}

- (void)errorMode;
{
    [self _styleCell];
    
    self.spinner.hidden = YES;
    
    // TODO: need error image
    if (!self.bottom) {
        self.backgroundColor = [UIColor redColor];
    }
}

#pragma mark Private methods

- (void)_styleCell;
{
    self.topBanner.hidden = self.bottom;
    self.bottomBanner.hidden = self.bottom;
    self.border.hidden = self.bottom;
}

@end
