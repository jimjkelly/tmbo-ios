//
//  TMBOImageDetailViewController.m
//  TMBO
//
//  Created by Scott Perry on 09/22/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOImageDetailViewController.h"

#import <UIImageView+AFNetworking.h>

#import "TMBOImageScrollView.h"
#import "TMBOUpload.h"

@interface TMBOImageDetailViewController ()
@end

@implementation TMBOImageDetailViewController
@synthesize upload;
@synthesize scrollView;
@synthesize imageView;
@synthesize spinner;

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    // TODO: do a better job of managing the navigation controller than this. menu bar overlay that shows on tap?
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [swipe setDirection: UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipe];
    
    // Loading!
    [spinner startAnimating];
    
    // Default configuration for zooming scrollview
//    [self.scrollView setMinimumZoomScale:1.0];
//    [self.scrollView setMaximumZoomScale:1.0];
    [self.scrollView setDelegate:self];
    [self.scrollView setImageView:self.imageView];
    
    NSURL *fileURL = [NSURL URLWithString:[upload fileURL] relativeToURL:kTMBOBaseURL];
    
    // TODO: 1) get image with progress 2) get image via model, so model can update thumbnail/cache
    [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:fileURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
        
        [self.scrollView setContentSize:[image size]];
        [self.imageView setFrame:CGRectMake(0.0, 0.0, [image size].width, [image size].height)];
        
        CGFloat minScale = [self minScaleForImage:image inContainer:[self.scrollView frame].size];
        [self.scrollView setMinimumZoomScale:minScale];
        [self.scrollView setMaximumZoomScale:[[UIScreen mainScreen] scale]];
        
        [self.scrollView setZoomScale:[self.scrollView minimumZoomScale] animated:NO];
        
        [spinner stopAnimating];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
        // TODO: Failure *is* an option
    }];
}

#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
    return imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
{
    
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
    } else {
        NSLog(@"%@", swipe);
    }
}

@end
