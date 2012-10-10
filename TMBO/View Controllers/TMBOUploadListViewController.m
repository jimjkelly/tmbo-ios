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
@property (nonatomic, strong) NSMutableArray *loading;
@property (nonatomic, strong) TMBOObjectList *uploads;
@property (nonatomic, assign) kTMBOType type;
@end

@implementation TMBOUploadListViewController
@synthesize loading = _loading;
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
    _loading = [[NSMutableArray alloc] init];
    
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
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 45.0f;
    
    // TODO: persistent store
    //[self _addUploads:[[TMBODataStore sharedStore] cachedUploadsWithType:self.type near:<#lastposition#>]];

    // Set up the lower limit
    self.uploads.minimumID = @(kFirstUploadID);
    [self.tableView setNeedsDisplay];
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
        
        loadCell.bottom = (range.first == kFirstUploadID);
        
        cell = loadCell;
    } else {
        NotReached();
    }
    
    return cell;
}

#pragma mark Helpers

- (UITableViewCell *)cellForObject:(id)object;
{
    // Get the upload's index in the array
    NSUInteger objectIndex = [self.uploads.items indexOfObject:object];
    if (objectIndex == NSNotFound) NotReached();
    
    for (NSIndexPath *path in [self.tableView indexPathsForVisibleRows]) {
        if ([path row] == objectIndex) {
            return [self.tableView cellForRowAtIndexPath:path];
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
    Assert([uitvc isKindOfClass:[TMBOLoadingCell class]]);
    
    TMBORange *range = (TMBORange *)[self.uploads.items objectAtIndex:indexPath.row];
    TMBOLoadingCell *cell = (TMBOLoadingCell *)uitvc;
    
    // Only interested in the bottom-most loading cell
    if (range.first != kFirstUploadID) {
        cell.mode = TMBOLoadingCellModeDefault;
        [cell setNeedsDisplay];
        return;
    }

    [self _loadUploadsForRange:range];
    cell.mode = TMBOLoadingCellModeLoading;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[self.uploads.items objectAtIndex:indexPath.row] isKindOfClass:[TMBORange class]]) {
        TMBORange *range = (TMBORange *)[self.uploads.items objectAtIndex:indexPath.row];
        TMBOLoadingCell *cell = (TMBOLoadingCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        Assert([cell isKindOfClass:[TMBOLoadingCell class]]);

        [self _loadUploadsForRange:range];
        cell.mode = TMBOLoadingCellModeLoading;
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        Assert([[self.uploads.items objectAtIndex:indexPath.row] isKindOfClass:[TMBOUpload class]]);
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
            TMBOUploadCell *cell = (TMBOUploadCell *)[self cellForObject:upload];
            if (!cell || ![cell isKindOfClass:[TMBOUploadCell class]]) return;
            
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
            TMBOUploadCell *cell = (TMBOUploadCell *)[self cellForObject:upload];
            if (!cell || ![cell isKindOfClass:[TMBOUploadCell class]]) return;

            [self configureCell:cell withUpload:upload];
            [cell setNeedsDisplay];
        });
    }
}

#pragma mark - Private methods

- (void)_loadUploadsForRange:(TMBORange *)range;
{
    void (^completion)(NSArray *,NSError *) = ^(NSArray *results, NSError *error) {
        Assert(!!results ^ !!error);
        if (results) {
            [self _addUploads:results];
        } else if (error) {
            TMBOLoadingCell *cell = (TMBOLoadingCell *)[self cellForObject:range];
            if (cell && [cell isKindOfClass:[TMBOLoadingCell class]]) {
                cell.mode = TMBOLoadingCellModeError;
            }
            NSLog(@"Refresh error: %@", [error localizedDescription]);
        }
        
        // Finished loading this range
        @synchronized (self.loading) {
            [self.loading removeObject:range];
        }
    };
    
    // Avoid dogpiling requests for this range
    @synchronized (self.loading) {
        if ([self.loading containsObject:range]) return;
        [self.loading addObject:range];
    }
    
    if (range.last == NSIntegerMax) {
        // Top loading can only mean one thing: no uploads yet! Oh no!
        [[TMBODataStore sharedStore] latestUploadsWithType:self.type completion:completion];
    } else if (range.first == kFirstUploadID) {
        // Bottom loading: load last -> first
        [[TMBODataStore sharedStore] uploadsWithType:self.type before:range.last completion:completion];
    } else {
        // Middle loading: load first -> last
        [[TMBODataStore sharedStore] uploadsWithType:self.type since:range.first completion:completion];
    }
}

// Uploads array MUST BE CONTIGUOUS! Call multiple times for disparate uploads.
- (void)_addUploads:(NSArray *)immutableUploads;
{
    Assert([immutableUploads count]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO: first time should be extra special. Special error screen on load fail, special all kinds of things
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Assert([self.uploads.items count] == 1);

            // Set up pull-to-refresh
            self.topRefresh = [[UIRefreshControl alloc] init];
            [self.topRefresh addTarget:self action:@selector(refreshControlEvent:) forControlEvents:UIControlEventValueChanged];
            [self setRefreshControl:self.topRefresh];
            [[self view] addSubview:self.topRefresh];
            
            // Set up row borders
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
        });

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
            [self.tableView setContentOffset:offset animated:NO];
        }
    });
}

@end
