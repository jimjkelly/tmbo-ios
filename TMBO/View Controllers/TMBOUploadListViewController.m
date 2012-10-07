//
//  TMBOUploadListViewController.m
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
#import "TMBOImageDetailViewController.h"
#import "TMBORange.h"
#import "TMBOUpload.h"
#import "TMBOUploadCell.h"
#import "TMBOUploadDetailViewController.h"
#import "UIImage+TMBOAssets.h"

static void *kUploadThumbnailContext = (void *)"TMBOUploadThumbnailContext";
static void *kUploadCommentsContext = (void *)"TMBOUploadCommentsContext";

static NSString * const kTMBOUploadCellName = @"TMBOUploadCell";

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
        [up removeObserver:self forKeyPath:@"comments" context:kUploadCommentsContext];
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
                    [up addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:kUploadCommentsContext];
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
    
    UINib *nib = [UINib nibWithNibName:kTMBOUploadCellName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kTMBOUploadCellName];
    
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTMBOUploadCellName];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kTMBOUploadCellName];
    
    [self initializeCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark Helpers

- (TMBOUploadCell *)cellForUpload:(TMBOUpload *)upload;
{
    // Get the upload's index in the array
    NSUInteger uploadIndex = [self.items indexOfObject:upload];
    if (uploadIndex == NSNotFound) NotReached();
    
    for (NSIndexPath *path in [self.tableView indexPathsForVisibleRows]) {
        if ([path row] == uploadIndex) {
            return (TMBOUploadCell *)[self.tableView cellForRowAtIndexPath:path];
        }
    }
    
    return nil;
}

- (void)displayThumbnailForUpload:(TMBOUpload *)upload onCell:(TMBOUploadCell *)cell;
{
    if (upload.thumbURL) {
        UIImage *thumbnail = [upload thumbnail];

        if (thumbnail && ![[upload filtered] boolValue]) {
            // Thumbnail present and ready
            [[cell spinner] stopAnimating];
            [[cell thumbnailView] setImage:thumbnail];
        } else if ([[upload filtered] boolValue]) {
            // Upload is filtered
            [[cell spinner] stopAnimating];
            [[cell thumbnailView] setImage:[UIImage thumbnailForFilteredUpload]];
        } else {
            // Thumbnail needed and not available, the caller takes care of this.
        }
    } else {
        // Upload has no thumbnail
        [[cell spinner] stopAnimating];
        CGRect thumbFrame = [[cell thumbnailView] frame];
        thumbFrame.size.width = 0;
        [[cell thumbnailView] setFrame:thumbFrame];
    }
}

- (void)initializeCell:(UITableViewCell *)uitvCell atIndexPath:(NSIndexPath *)indexPath;
{
    if ([uitvCell isKindOfClass:[TMBOUploadCell class]]) {
        TMBOUploadCell *cell = (TMBOUploadCell *)uitvCell;
        TMBOUpload *upload = [self.items objectAtIndex:[indexPath row]];
        Assert([upload isKindOfClass:[TMBOUpload class]]);
        
        // Set up normal cell state
        [self configureCell:cell withData:upload];
        
        // Set up initial cell state
        [cell.spinner startAnimating];
        [self displayThumbnailForUpload:upload onCell:cell];
        
        // If there's no acceptible thumbnail, request one.
        UIImage *thumbnail = [upload thumbnail];
        CGSize thumbsize = [cell.thumbnailView bounds].size;
        thumbsize.width *= [[UIScreen mainScreen] scale];
        thumbsize.height *= [[UIScreen mainScreen] scale];
        
        if (upload.thumbURL && (!thumbnail || [thumbnail size].height < thumbsize.height || [thumbnail size].width < thumbsize.width)) {
            [upload refreshThumbnailWithMinimumSize:thumbsize];
        }
    } else {
        NotReached();
    }
}

- (void)configureCell:(UITableViewCell *)uitvCell atIndexPath:(NSIndexPath *)indexPath;
{
    id data = [self.items objectAtIndex:[indexPath row]];

    [self configureCell:uitvCell withData:data];
}

- (void)configureCell:(UITableViewCell *)uitvCell withData:(id)data;
{
    if ([uitvCell isKindOfClass:[TMBOUploadCell class]]) {
        Assert([data isKindOfClass:[TMBOUpload class]]);
        TMBOUpload *upload = (TMBOUpload *)data;
        TMBOUploadCell *cell = (TMBOUploadCell *)uitvCell;
        
        [[cell filenameView] setText:[upload filename]];
        // TODO: L10n
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
    } else {
        NotReached();
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

#pragma mark KVO notifications for updating upload cells

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    Assert([object isKindOfClass:[TMBOUpload class]]);
    TMBOUpload *upload = (TMBOUpload *)object;
    
    id newObject = [change objectForKey:@"new"];
    if (context == kUploadThumbnailContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            TMBOUploadCell *cell = [self cellForUpload:upload];
            if (!cell) return;
            
            if (newObject) {
                Assert([newObject isKindOfClass:[UIImage class]]);
                [self displayThumbnailForUpload:upload onCell:cell];
            } else {
                // TODO: Add a layer over the thumbnail that, if tapped and thumbnail is not set, causes a retry for the thumbnail. In the meantime, come up with an sset to put here that indicates that the load failed.
                [[cell spinner] stopAnimating];
            }
            
            [cell setNeedsDisplay];
        });
    }
    
    if (context == kUploadCommentsContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            TMBOUploadCell *cell = [self cellForUpload:upload];
            [self configureCell:cell withData:upload];
        });
    }
}

// TODO: handle lazyloading at the bottom

@end
