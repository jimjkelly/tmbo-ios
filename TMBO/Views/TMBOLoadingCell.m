//
//  TMBOLoadingCell.m
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOLoadingCell.h"

@implementation TMBOLoadingCell
@synthesize spinner;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
