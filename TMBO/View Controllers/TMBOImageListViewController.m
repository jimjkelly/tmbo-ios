//
//  TMBOImageListViewController.m
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOImageListViewController.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "TMBOImageListCell.h"
#import "TMBOImageDetailViewController.h"
#import "TMBOUpload.h"
#import "UIImage+Resize.h"

@interface TMBOImageListViewController () {
    UIRefreshControl *_topRefresh;
}
- (void)refetchData;
@end

@implementation TMBOImageListViewController

- (void)refetchData;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_topRefresh beginRefreshing];
        [_topRefresh endRefreshing];
    });
}

#pragma mark - UITableViewController

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

// HACK: this is part of the hack described above
- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    // …
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (!self) return nil;
    
    // …
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self refetchData];
    
    UINib *nib = [UINib nibWithNibName:@"TMBOImageListCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"TMBOImageListCell"];
    
    _topRefresh = [[UIRefreshControl alloc] init];
    [_topRefresh addTarget:self action:@selector(refreshControlEvent:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:_topRefresh];
    [[self view] addSubview:_topRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TMBOImageListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)uitvcell
          atIndexPath:(NSIndexPath *)indexPath
{
    TMBOImageListCell *cell = (TMBOImageListCell *)uitvcell;
    @try {
        TMBOUpload *upload = (TMBOUpload *)nil; // TODO: set to thing
        
        [[cell filenameView] setText:[upload filename]];
        
        [[cell uploaderView] setText:[NSString stringWithFormat:@"uploaded by %@", [upload username]]];
        
        NSString *commentsLabel;
        if ([upload comments] == 0) {
            commentsLabel = @"0 comments";
        } else if ([upload comments] == 1) {
            commentsLabel = @"1 comment";
        } else {
            commentsLabel = [NSString stringWithFormat:@"%u comments", [upload comments]];
        }
        [[cell commentsView] setText:commentsLabel];
        
        NSString *votesLabel = [NSString stringWithFormat:@"+%u -%u", [upload goodVotes], [upload badVotes]];
        if ([upload tmboVotes]) {
            votesLabel = [votesLabel stringByAppendingFormat:@" x%u", [upload tmboVotes]];
        }
        [[cell votesView] setText:votesLabel];
        
        UIImage *thumbnail = [upload thumbnail];
        if (thumbnail && ![upload filtered]) {
            [[cell spinner] stopAnimating];
            [[cell thumbnailView] setImage:thumbnail];
        } else if ([upload filtered]) {
            [[cell spinner] stopAnimating];
            [[cell thumbnailView] setImage:[UIImage imageNamed:@"th-filtered"]];
        }
        if (![upload thumbURL]) {
            [[cell spinner] stopAnimating];
            CGRect thumbFrame = [[cell thumbnailView] frame];
            thumbFrame.size.width = 0;
            [[cell thumbnailView] setFrame:thumbFrame];
        }
        
        // Image stuff is potentially slow, so get off the main thread right away.
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // Compute ideal thumbnail size in pixels (not points)
            CGSize thumbsize = [[cell thumbnailView] bounds].size;
            thumbsize.width *= [[UIScreen mainScreen] scale];
            thumbsize.height *= [[UIScreen mainScreen] scale];
            
            if ([upload thumbURL] && (!thumbnail || [thumbnail size].height < thumbsize.height || [thumbnail size].width < thumbsize.width)) {
                // Thumbnail is not good enough. Load another!
                NSURL *thumbURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://thismight.be%@", [upload thumbURL]]];
                NSURLRequest *req = [NSURLRequest requestWithURL:thumbURL cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:60.0];
                
                AFImageRequestOperation *afop = [AFImageRequestOperation imageRequestOperationWithRequest:req imageProcessingBlock:^UIImage *(UIImage *image){
                        UIImage *thumb = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:thumbsize interpolationQuality:kCGInterpolationHigh];
                        [upload setThumbnail:thumb];
                        return thumb;
                    }
                    success:^(NSURLRequest *request , NSHTTPURLResponse *response , UIImage *image ) {
                        // TODO: Get the cell for this upload again
                        TMBOImageListCell *validCell = nil;
                        
                        if (validCell) {
                            [[validCell spinner] stopAnimating];
                            if (![upload filtered]) {
                                [[validCell thumbnailView] setImage:image];
                            }
                            [validCell setNeedsDisplay];
                        }
                    }
                    failure:^( NSURLRequest *request , NSHTTPURLResponse *response , NSError *error ){
                        // TODO: Get the cell for this upload again
                        TMBOImageListCell *validCell = nil;

                        if (validCell) {
                            [[cell spinner] stopAnimating];
                            // TODO: failure?
                            /* Plan:
                             * Add a layer over the thumbnail that, if tapped and thumbnail is not set, causes a retry for the thumbnail. In the meantime, come up with an asset to put here that indicates that the load failed.
                             */
                            [cell setNeedsDisplay];
                        }
                    }];
                
                [afop start];
            }
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
}

#pragma mark - UITableViewDelegate

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return [TweetTableViewCell heightForCellWithTweet:(Tweet *)[_fetchedResultsController objectAtIndexPath:indexPath]];
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    TMBOImageDetailViewController *detailViewController = [[TMBOImageDetailViewController alloc] init];
    [detailViewController setUpload:nil]; // TODO: set to thing
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSUInteger)supportedInterfaceOrientations;
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark Target-action for UIRefreshControl

- (void)refreshControlEvent:(UIRefreshControl *)something;
{
    [self refetchData];
}

@end
