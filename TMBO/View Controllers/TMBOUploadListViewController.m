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
#import "TMBOLoadingCell.h"
#import "TMBOObjectList.h"
#import "TMBORange.h"
#import "TMBOUploadCell.h"
#import "TMBOUploadDetailViewController.h"
#import "UIImage+TMBOAssets.h"

static void *kUploadThumbnailContext = (void *)"TMBOUploadThumbnailContext";
static void *kUploadCommentsContext = (void *)"TMBOUploadCommentsContext";

static NSString * const kTMBOUploadCellName = @"TMBOUploadCell";
static NSString * const kTMBOLoadingCellName = @"TMBOLoadingCell";

@interface TMBOUploadListViewController ()
@property (nonatomic, strong) UIRefreshControl *topRefresh;
@property (nonatomic, strong) NSNumber *bottomRefresh;
@property (nonatomic, strong) TMBOObjectList *uploads;
@property (nonatomic, assign) kTMBOType type;
@end

@implementation TMBOUploadListViewController
@synthesize topRefresh = _topRefresh;
@synthesize type = _type;
@synthesize uploads = _uploads;

- (id)initWithType:(kTMBOType)type;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;
    
    _type = type;
    _uploads = [[TMBOObjectList alloc] init];
    {
        __weak id this = self;
        [_uploads setRemovedObject:^(id<TMBOObject>object) {
            Assert([object isKindOfClass:[TMBOUpload class]]);
            TMBOUpload *upload = (TMBOUpload *)object;
            [upload removeObserver:this forKeyPath:@"thumbnail" context:kUploadThumbnailContext];
            [upload removeObserver:this forKeyPath:@"comments" context:kUploadCommentsContext];
        }];
        [_uploads setAddedObject:^(id<TMBOObject>object) {
            Assert([object isKindOfClass:[TMBOUpload class]]);
            TMBOUpload *upload = (TMBOUpload *)object;
            [upload addObserver:this forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionNew context:kUploadThumbnailContext];
            [upload addObserver:this forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:kUploadCommentsContext];
        }];
    }
    
    return self;
}

- (void)dealloc;
{
    // Clean up observers
    [_uploads destroy];
}

#pragma mark - UITableViewController

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:kTMBOUploadCellName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kTMBOUploadCellName];
    
    nib = [UINib nibWithNibName:kTMBOLoadingCellName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kTMBOLoadingCellName];
    
    self.topRefresh = [[UIRefreshControl alloc] init];
    [self.topRefresh addTarget:self action:@selector(refreshControlEvent:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:self.topRefresh];
    [[self view] addSubview:self.topRefresh];
    
    //[self.items addObjectsFromArray:[[TMBODataStore sharedStore] cachedUploadsWithType:self.type near:<#lastposition#>]];

    [self refreshControlEvent:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.uploads.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    id rowData = [self.uploads.items objectAtIndex:indexPath.row];
    
    if ([rowData isKindOfClass:[TMBOUpload class]]) {
        TMBOUploadCell *upCell;
        TMBOUpload *upload = (TMBOUpload *)rowData;
        
        upCell = [tableView dequeueReusableCellWithIdentifier:kTMBOUploadCellName];
        if (!upCell) upCell = [[TMBOUploadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kTMBOUploadCellName];
    
        [self initializeCell:upCell withUpload:upload];
        
        cell = upCell;
    } else if ([rowData isKindOfClass:[TMBORange class]]) {
        TMBOLoadingCell *loadCell;
        TMBORange *range = (TMBORange *)rowData;
        
        loadCell = [tableView dequeueReusableCellWithIdentifier:kTMBOLoadingCellName];
        if (!loadCell) loadCell = [[TMBOLoadingCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kTMBOLoadingCellName];
        
        if (range.first == kFirstUploadID) {
            [loadCell.spinner startAnimating];
            // TODO: Automatically load the next batch of uploads
        } else {
            // TODO: non-bottom ranges
        }
        
        cell = loadCell;
    } else {
        NotReached();
    }
    
    return cell;
}

#pragma mark Helpers

- (TMBOUploadCell *)cellForUpload:(TMBOUpload *)upload;
{
    // Get the upload's index in the array
    NSUInteger uploadIndex = [self.uploads.items indexOfObject:upload];
    if (uploadIndex == NSNotFound) NotReached();
    
    for (NSIndexPath *path in [self.tableView indexPathsForVisibleRows]) {
        if ([path row] == uploadIndex) {
            return (TMBOUploadCell *)[self.tableView cellForRowAtIndexPath:path];
        }
    }
    
    return nil;
}

- (void)initializeCell:(TMBOUploadCell *)cell withUpload:(TMBOUpload *)upload;
{
    // Set up normal cell state
    [self configureCell:cell withUpload:upload];
    
    // If there's no acceptible thumbnail, request one.
    UIImage *thumbnail = [upload thumbnail];
    CGSize thumbsize = [cell.thumbnailView bounds].size;
    thumbsize.width *= [[UIScreen mainScreen] scale];
    thumbsize.height *= [[UIScreen mainScreen] scale];
    
    if (upload.thumbURL && (!thumbnail || [thumbnail size].height < thumbsize.height || [thumbnail size].width < thumbsize.width)) {
        [cell.spinner startAnimating];
        [upload refreshThumbnailWithMinimumSize:thumbsize];
    }
}

- (void)configureCell:(TMBOUploadCell *)cell withUpload:(TMBOUpload *)upload;
{
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)uitvc forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    // Only interested in LoadingListCells
    if (![[self.uploads.items objectAtIndex:indexPath.row] isKindOfClass:[TMBORange class]]) return;

    TMBORange *range = (TMBORange *)[self.uploads.items objectAtIndex:indexPath.row];
    
    // Only interested in the bottom-most loading cell
    if (range.first != kFirstUploadID) return;
    
    // Only one request running at a time
    @synchronized (self.bottomRefresh) {
        if ([self.bottomRefresh boolValue]) return;
        
        // Fetch uploads
        self.bottomRefresh = @(YES);
    }
    
    // TODO: handle last == NSIntegerMax as latestUploads
    [[TMBODataStore sharedStore] uploadsWithType:kTMBOTypeImage before:range.last completion:^(NSArray *results, NSError *error) {
        Assert(!!results ^ !!error);
        if (results) {
            [self _addUploads:results];
        } else if (error) {
            NSLog(@"Refresh error: %@", [error localizedDescription]);
        }
        self.bottomRefresh = NO;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: handle selecting of loadingCells
    // TODO: handle selecting of loadingCells with last == NSIntegerMax
    
    // Navigation logic may go here. Create and push another view controller.
    TMBOUpload *upload = [self.uploads.items objectAtIndex:[indexPath row]];
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

- (void)refreshControlEvent:(UIRefreshControl *)refreshControl;
{
    [self.topRefresh beginRefreshing];
    
    [[TMBODataStore sharedStore] latestUploadsWithType:kTMBOTypeImage completion:^(NSArray *results, NSError *error) {
        Assert(!!results ^ !!error);
        
        if (results) {
            [self _addUploads:results];
        } else if (error) {
            NSLog(@"Refresh error: %@", [error localizedDescription]);
        }

        // First time running, whether success or failure, show the bottom loader
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.uploads.minimumID = @(kFirstUploadID);
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.topRefresh endRefreshing];
        });
    }];
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
                [self configureCell:cell withUpload:upload];
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
            if (!cell) return;

            [self configureCell:cell withUpload:upload];
            [cell setNeedsDisplay];
        });
    }
}

#pragma mark - Private methods

// Uploads array MUST BE CONTIGUOUS! Call multiple times for disparate uploads.
- (void)_addUploads:(NSArray *)immutableUploads;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the viewport scroll offset, to preserve when top/middle-loading
        // TODO: caller should figure out offset.y (+= self.tableView.rowHeight)
        // Get the offset to the nearest visible upload, and we'll use that as the basis for our math
        CGPoint offset = [self.tableView contentOffset];

        [self.uploads addObjectsFromArray:immutableUploads];
        
        [self.tableView reloadData];
        if (offset.y < 0) {
            offset.y = 0;
            [self.tableView setContentOffset:offset animated:YES];
        } else {
            // TODO: test this with animation
            [self.tableView setContentOffset:offset animated:NO];
        }
    });
}

@end
