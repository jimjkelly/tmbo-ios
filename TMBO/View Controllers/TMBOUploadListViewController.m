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

#import "TMBOUploadListViewController.h"

#import "TMBODataStore.h"
#import "TMBOImageListCell.h"
#import "TMBOImageDetailViewController.h"
#import "TMBOUpload.h"
#import "TMBOUploadDetailViewController.h"
#import "AFNetworking.h"
#import "UIImage+Resize.h"

static void *kUploadThumbnailContext = (void *)"TMBOUploadThumbnailContext";

@interface TMBOUploadListViewController ()
@property (nonatomic, strong) UIRefreshControl *topRefresh;
@property (nonatomic, strong) NSMutableArray *items;
- (void)refetchData;
@end

@implementation TMBOUploadListViewController
@synthesize topRefresh = _topRefresh;
@synthesize items = _items;

- (void)dealloc;
{
    for (TMBOUpload *up in _items) {
        [up removeObserver:self forKeyPath:@"thumbnail" context:kUploadThumbnailContext];
    }
}

- (void)refetchData;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.topRefresh beginRefreshing];
    });
    
    // TODO: new upload getting code, this stuff is CRUFTY!
    void (^completion)(NSArray *, NSError *) = ^(NSArray *results, NSError *error){
        if (results) {
            NSUInteger max = 111;
            max = ![self.items count] ?: [[[self.items objectAtIndex:0] uploadid] unsignedIntegerValue];
                
            // Add non-duplicate uploads
            for (TMBOUpload *up in results) {
                if ([[up uploadid] unsignedIntegerValue] > max) {
                    [up addObserver:self forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionNew context:kUploadThumbnailContext];
                    [self.items insertObject:up atIndex:0];
                }
            }
            
            // Verify sort order
            [self.items sortUsingComparator:kUploadComparator];
            
            // TODO: is updating the table going to jerk around the location of the viewport in relation to the uploads? maybe use -beginUpdates instead?
            // reloadData must be sent on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        } else if (error) {
            NSLog(@"Refresh error: %@", [error localizedDescription]);
        } else {
            NotReached();
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.topRefresh endRefreshing];
        });
    };
    
    if ([self.items count]) {
        [[TMBODataStore sharedStore] uploadsWithType:kTMBOTypeImage since:[[[self.items objectAtIndex:0] uploadid] unsignedIntegerValue] completion:completion];
    } else {
        [[TMBODataStore sharedStore] latestUploadsWithType:kTMBOTypeImage completion:completion];
    }
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
    
    UINib *nib = [UINib nibWithNibName:@"TMBOImageListCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"TMBOImageListCell"];
    
    self.topRefresh = [[UIRefreshControl alloc] init];
    [self.topRefresh addTarget:self action:@selector(refreshControlEvent:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:self.topRefresh];
    [[self view] addSubview:self.topRefresh];
    
    self.items = [[NSMutableArray alloc] init];
    //[self.items addObjectsFromArray:[[TMBODataStore sharedStore] cachedUploadsWithType:kTMBOTypeImage near:<#lastposition#>]];

    [self refetchData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TMBOImageListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark Helpers

- (TMBOImageListCell *)cellForUpload:(TMBOUpload *)upload;
{
    // Get the upload's index in the array
    NSUInteger uploadIndex = [self.items indexOfObject:upload];
    if (uploadIndex == NSNotFound) return nil; // TODO: explode?
    
    for (NSIndexPath *path in [self.tableView indexPathsForVisibleRows]) {
        if ([path row] == uploadIndex) {
            return (TMBOImageListCell *)[self.tableView cellForRowAtIndexPath:path];
        }
    }
    
    return nil;
}

- (void)configureCell:(TMBOImageListCell *)cell atIndexPath:(NSIndexPath *)indexPath;
{
    TMBOUpload *upload = [self.items objectAtIndex:[indexPath row]];
    
    [[cell filenameView] setText:[upload filename]];
    [[cell uploaderView] setText:[NSString stringWithFormat:@"uploaded by %@", [upload username]]];
    
    NSString *commentsLabel;
    {
        // TODO: L10n
        if ([upload comments] == 0) {
            commentsLabel = @"0 comments";
        } else if ([[upload comments] unsignedIntegerValue] == 1) {
            commentsLabel = @"1 comment";
        } else {
            commentsLabel = [NSString stringWithFormat:@"%@ comments", [upload comments]];
        }
    }
    [[cell commentsView] setText:commentsLabel];
    
    UIImage *thumbnail = [upload thumbnail];
    {
        if (thumbnail && ![[upload filtered] boolValue]) {
            // Thumbnail present and ready
            [[cell spinner] stopAnimating];
            [[cell thumbnailView] setImage:thumbnail];
        } else if ([[upload filtered] boolValue]) {
            // Upload is filtered
            [[cell spinner] stopAnimating];
            [[cell thumbnailView] setImage:[UIImage imageNamed:@"th-filtered"]];
        }
        if (![upload thumbURL]) {
            // Upload has no thumbnail
            [[cell spinner] stopAnimating];
            CGRect thumbFrame = [[cell thumbnailView] frame];
            thumbFrame.size.width = 0;
            [[cell thumbnailView] setFrame:thumbFrame];
        }
    }
    
    // Compute ideal thumbnail size in pixels (not points)
    CGSize thumbsize = [[cell thumbnailView] bounds].size;
    thumbsize.width *= [[UIScreen mainScreen] scale];
    thumbsize.height *= [[UIScreen mainScreen] scale];
    
    if ([upload thumbURL] && (!thumbnail || [thumbnail size].height < thumbsize.height || [thumbnail size].width < thumbsize.width)) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // Thumbnail is not good enough. Load another!
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://thismight.be%@", [upload thumbURL]]];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                Assert([responseObject isKindOfClass:[NSData class]]);
                if ([responseObject isKindOfClass:[NSData class]]) {
                    UIImage *image = [UIImage imageWithData:responseObject];
                    UIImage *thumb = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:thumbsize interpolationQuality:kCGInterpolationHigh];
                    
                    // Causes a KVO notification. If a cell is currently displaying this upload, it will be updated.
                    [upload setThumbnail:thumb];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                TMBOImageListCell *validCell = [self cellForUpload:upload];
                [[validCell spinner] stopAnimating];
                [validCell setNeedsDisplay];

                // TODO: failure?
                NSLog(@"%@ had error: %@", operation, error);
                /* Plan:
                 * Add a layer over the thumbnail that, if tapped and thumbnail is not set, causes a retry for the thumbnail. In the meantime, come up with an sset to put here that indicates that the load failed.
                 */
            }];
            
            [operation start];
        });
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    TMBOUpload *upload = [self.items objectAtIndex:[indexPath row]];
    TMBOUploadDetailViewController *detailView = nil;
    switch ([upload kindOfUpload]) {
        case kTMBOTypeImage:
            detailView = [[TMBOImageDetailViewController alloc] init];
            break;
            
        // Other upload types go here…
            
        default:
            break;
    }

    if (detailView) {
        [detailView setUpload:upload];
        [self.navigationController pushViewController:detailView animated:YES];
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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

#pragma mark KVO notifications for updating cells

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    Assert([object isKindOfClass:[TMBOUpload class]]);
    TMBOUpload *upload = (TMBOUpload *)object;
    
    id newObject = [change objectForKey:@"new"];
    if (context == kUploadThumbnailContext && newObject && [newObject isKindOfClass:[UIImage class]]) {
        TMBOImageListCell *cell = [self cellForUpload:upload];
        
        [[cell spinner] stopAnimating];
        if (![[upload filtered] boolValue]) {
            [[cell thumbnailView] setImage:newObject];
        }
        [cell setNeedsDisplay];
        
    }
}

// TODO: handle lazyloading at the bottom

@end
