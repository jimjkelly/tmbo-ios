//
//  TMBOLoginViewController.m
//  TMBO
//
//  Created by James Kelly on 9/25/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOLoginViewController.h"

#import "TMBODataStore.h"

@interface TMBOLoginViewController ()
@property (nonatomic, strong) id refreshTarget;
@property (nonatomic, assign) SEL action;
@end

@implementation TMBOLoginViewController

- (IBAction)loginPressed:(UIButton *)sender {
    self.loginError.hidden = YES;
    self.activity.hidden = NO;
    [self.activity startAnimating];
        
    [[TMBODataStore sharedStore] authenticateUsername:[self.username text] password:[self.password text] completion:^(NSError *error){
        if (error) {
            // TODO: Better handle error conditions
            NSLog(@"Error authenticating: %@", error);
            [self loginFailed];
        } else {
            [self closeLoginWindow];
            [self.refreshTarget performSelector:self.action];
        }
    }];
}

- (void)closeLoginWindow {
    if([NSThread isMainThread]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self performSelectorOnMainThread:@selector(closeLoginWindow) withObject:nil waitUntilDone:YES];
    }
}

- (void)loginFailed {
    // do stuffs for a login failure
    [self.activity stopAnimating];
    self.activity.hidden = YES;
    self.loginError.hidden = NO;
    // TODO: support richer login error messages
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Used to store a refresh target after login
- (id)initWithRefreshTarget:(id)target action:(SEL)action {
    self = [super init];
    if (self) {
        self.refreshTarget = target;
        self.action = action;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Set acitivy indicator and errors to hidden
    self.activity.hidden = YES;
    self.loginError.hidden = YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
