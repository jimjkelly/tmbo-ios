//
//  TMBOLoadingCell.h
//  TMBO
//
//  Created by Scott Perry on 10/07/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    TMBOLoadingCellModeDefault,
    TMBOLoadingCellModeLoading,
    TMBOLoadingCellModeError
} TMBOLoadingCellMode;

@interface TMBOLoadingCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *topBanner;
@property (weak, nonatomic) IBOutlet UIImageView *bottomBanner;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, assign) BOOL bottom;
@property (nonatomic, assign) TMBOLoadingCellMode mode;
@end
