//
//  TMBOImageDetailViewController.h
//  TMBO
//
//  Created by Scott Perry on 09/22/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMBOUpload;
@class TMBOImageScrollView;

@interface TMBOImageDetailViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, strong) TMBOUpload *upload;
@property (weak, nonatomic) IBOutlet TMBOImageScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end
