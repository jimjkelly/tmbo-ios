//
//  TMBOLoginViewController.h
//  TMBO
//
//  Created by James Kelly on 9/25/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMBOLoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UILabel *loginError;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@end
