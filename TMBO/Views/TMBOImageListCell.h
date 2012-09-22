//
//  TMBOImageListCell.h
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMBOImageListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *filenameView;
@property (weak, nonatomic) IBOutlet UILabel *uploaderView;
@property (weak, nonatomic) IBOutlet UILabel *commentsView;
@property (weak, nonatomic) IBOutlet UILabel *votesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
