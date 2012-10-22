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
#import "NNProgressCircleView.h"
#import "TMBOImageScrollView.h"
#import "TMBOUpload.h"
#import "UIImageView+NDVAnimatedGIFSupport.h"

@interface TMBOImageDetailViewController ()
- (void)fit;
@end

@implementation TMBOImageDetailViewController

#pragma mark Factored functionality

// Called in the image load success completion block and viewWillAppear
- (void)fit;
{
    if (!self.imageView.image) return;
    
    CGFloat minScale = [self minScaleForImage:self.imageView.image inContainer:self.scrollView.frame.size];
    [self.scrollView setMinimumZoomScale:minScale];
    [self.scrollView setMaximumZoomScale:[[UIScreen mainScreen] scale]];
    
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:NO];
}

#pragma mark - UIView overloaded methods

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    // TODO: do a better job of managing the navigation controller than this. menu bar overlay that shows on tap?
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [swipe setDirection: UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipe];
    
    // Loading!
    [self.spinner startAnimating];
    self.progressCircle.hidden = YES;
    
    // Default configuration for zooming scrollview
    [self.scrollView setMinimumZoomScale:1.0];
    [self.scrollView setMaximumZoomScale:1.0];
    [self.scrollView setDelegate:self];
    [self.scrollView setImageView:self.imageView];
    
    [self.upload getFileWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressCircle.hidden = YES;
            
            // TODO: maybe be less fatalistic about this
            Assert([responseObject isKindOfClass:[NSData class]]);
            NSData *responseData = (NSData *)responseObject;
            
            UIImage *image = [UIImage imageWithData:responseData];
            self.imageView.image = image;
            // TODO: maybe be less fatalistic about this
            Assert(image);
            
            [self.scrollView setContentSize:image.size];
            [self.imageView setFrame:CGRectMake(0.0, 0.0, image.size.width, image.size.height)];
            
            [self fit];
            
            // If this is an animated image, set up the animation
            [self.imageView setupAnimationWithData:responseData];
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

- (void)viewWillAppear:(BOOL)animated;
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self fit];
}

#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
    return self.imageView;
}

#pragma mark - Rotation resizing

- (CGFloat)minScaleForImage:(UIImage *)image inContainer:(CGSize)container;
{
    CGFloat minScale = MIN((container.width / image.size.width), (container.height / image.size.height));
    
    return MIN(minScale, 1.0);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
{
    CGFloat minScale = [self.scrollView minimumZoomScale];
    BOOL resize = minScale == [self.scrollView zoomScale];
    
    // Set new minScale
    minScale = [self minScaleForImage:[self.imageView image] inContainer:[self.scrollView frame].size];
    [self.scrollView setMinimumZoomScale:minScale];
    
    if (resize || minScale > [self.scrollView zoomScale]) {
        [self.scrollView setZoomScale:minScale];
    }
}

#pragma mark - Gesture recognition

- (void)swipe:(UISwipeGestureRecognizer *)swipe;
{
    if ([swipe direction] == UISwipeGestureRecognizerDirectionUp) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
