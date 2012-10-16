//
//  TMBOLoadingCell.m
//  TMBO
//
//  Created by Scott Perry on 10/07/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOLoadingCell.h"

NSString * const kTMBOLoadingCellName = @"TMBOLoadingCell";

@implementation TMBOLoadingCell
@synthesize spinner = _spinner;
@synthesize bottom = _bottom;

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
@synthesize mode = _mode;

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
    self.backgroundColor = [UIColor clearColor];
}

- (void)defaultMode;
{
    [self _styleCell];
    
    self.spinner.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
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
