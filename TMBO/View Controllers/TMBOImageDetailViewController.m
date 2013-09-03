//
//  TMBOImageDetailViewController.m
//  TMBO
//
//  Created by Scott Perry on 09/22/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOImageDetailViewController.h"

#import "AFNetworking.h"
#import "NNAnimatedGIFView.h"
#import "NNProgressCircleView.h"
#import "TMBOImageScrollView.h"
#import "TMBOUpload.h"
#import "UIImageView+ImageSize.h"

@interface TMBOImageDetailViewController ()
@property (nonatomic, assign) CGSize imageSize;

- (void)fit;
@end

@implementation TMBOImageDetailViewController

#pragma mark Factored functionality

// Called in the image load success completion block and viewWillAppear
- (void)fit;
{
    CGFloat minScale = [self minScaleForImage:self.imageSize inContainer:self.scrollView.frame.size];
    [self.scrollView setMinimumZoomScale:minScale];
    [self.scrollView setMaximumZoomScale:[[UIScreen mainScreen] scale]];
    
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:NO];
}

#pragma mark - UIView overloaded methods

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    // TODO: do a better job of managing the navigation controller than this. menu bar overlay that shows on tap?
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    
    [self getAndShowUpload];
}

- (void)getAndShowUpload {
    // unload any existing view
    [self.scrollView.contentView removeFromSuperview];
    
    // Loading!
    [self.spinner startAnimating];
    self.progressCircle.hidden = YES;
    
    // Default configuration for zooming scrollview
    [self.scrollView setMinimumZoomScale:1.0];
    [self.scrollView setMaximumZoomScale:1.0];
    [self.scrollView setDelegate:self];
    
    [self.upload getFileWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressCircle.hidden = YES;
            
            Assert([responseObject isKindOfClass:[NSData class]]);
            NSData *responseData = (NSData *)responseObject;
            // TODO: restore animated gif capabilities
            //UIView *contentView = [NNAnimatedGIFView imageViewForData:responseData];
            UIImage *image = [[UIImage alloc] initWithData:responseData];
            UIView *contentView = [[UIImageView alloc] initWithImage:image];
            [contentView setUserInteractionEnabled:YES];
            Assert([contentView isKindOfClass:[UIImageView class]] || [contentView isKindOfClass:[NNAnimatedGIFView class]]);
            self.imageSize = [(id<TMBOImageSize>)contentView imageSize];
            self.scrollView.contentView = contentView;

            [self fit];

            [self.spinner stopAnimating];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: Failure *is* an option
    } progress:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        [self.spinner stopAnimating];
        self.spinner.hidden = YES;
        self.progressCircle.hidden = NO;
        
        if (totalBytesRead == totalBytesExpectedToRead) {
            self.progressCircle.progress = 1.0f;
        } else {
            [self.progressCircle setProgress:((CGFloat)totalBytesRead / (CGFloat)totalBytesExpectedToRead) animated:YES];
        }
    }];
}

// Maybe handle this directly in here?

- (void)viewWillAppear:(BOOL)animated;
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self fit];
}

#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
    return self.scrollView.contentView;
}

#pragma mark - Rotation resizing

- (CGFloat)minScaleForImage:(CGSize)size inContainer:(CGSize)container;
{
    CGFloat minScale = MIN((container.width / size.width), (container.height / size.height));
    
    return MIN(minScale, 1.0);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
{
    CGFloat minScale = [self.scrollView minimumZoomScale];
    BOOL resize = minScale == [self.scrollView zoomScale];
    
    // Set new minScale
    minScale = [self minScaleForImage:self.imageSize inContainer:[self.scrollView frame].size];
    [self.scrollView setMinimumZoomScale:minScale];
    
    if (resize || minScale > [self.scrollView zoomScale]) {
        [self.scrollView setZoomScale:minScale];
    }
}

#pragma mark - Gesture recognition

- (void)swipe:(UISwipeGestureRecognizer *)swipe {
    if ([swipe direction] == UISwipeGestureRecognizerDirectionUp || [swipe direction] == UISwipeGestureRecognizerDirectionDown) {
        NSLog(@"ohai");
        TMBOUpload *nextUpload = [self.delegate respondTo:[swipe direction] from:[self upload]];
        
        if (nextUpload == self.upload) {
            // We've reached the end of the internet
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            self.upload = nextUpload;
        }
        
        [self getAndShowUpload];
    } else if ([swipe direction] == UISwipeGestureRecognizerDirectionRight) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
