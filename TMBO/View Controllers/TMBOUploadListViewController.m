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

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) kTMBOType type;
@end

@implementation TMBOUploadListViewController
@synthesize topRefresh = _topRefresh;
@synthesize items = _items;
@synthesize type = _type;

- (id)initWithType:(kTMBOType)type;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;
    
    _type = type;
    
    return self;
}

- (void)dealloc;
{
    for (TMBOUpload *up in _items) {
        [up removeObserver:self forKeyPath:@"thumbnail" context:kUploadThumbnailContext];
        [up removeObserver:self forKeyPath:@"comments" context:kUploadCommentsContext];
    }
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
    
    self.items = [[NSMutableArray alloc] init];
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
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    id rowData = [self.items objectAtIndex:indexPath.row];
    
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
    NSUInteger uploadIndex = [self.items indexOfObject:upload];
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
    if (![[self.items objectAtIndex:indexPath.row] isKindOfClass:[TMBORange class]]) return;

    TMBORange *range = (TMBORange *)[self.items objectAtIndex:indexPath.row];
    
    // Only interested in the bottom-most loading cell
    if (range.first != kFirstUploadID) return;
    
    // Only one request running at a time
    @synchronized (self.bottomRefresh) {
        if ([self.bottomRefresh boolValue]) return;
        
        // Fetch uploads
        self.bottomRefresh = @(YES);
    }
    
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
    if (![immutableUploads count]) return;
    NSMutableArray *uploads = [immutableUploads mutableCopy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [uploads sortUsingComparator:kUploadComparator];
        
        // Get the viewport scroll offset, to preserve when top/middle-loading
        CGPoint offset = [self.tableView contentOffset];
        
        if (![self.items count]) {
            // First population of table
            for (TMBOUpload *up in uploads) {
                // TODO: register as an observer for items as they get added? that would be much easier :(
                [up addObserver:self forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionNew context:kUploadThumbnailContext];
                [up addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:kUploadCommentsContext];
            }
            [self.items setArray:uploads];
            TMBORange *range = [[TMBORange alloc] initWithFirst:kFirstUploadID last:[[[self.items lastObject] uploadid] integerValue]];
            [self.items addObject:range];
        } else {
            // Assumptions:
            Assert([[self.items objectAtIndex:0] isKindOfClass:[TMBOUpload class]]); // TODO: not true if first loading failed?
            Assert([[self.items lastObject] isKindOfClass:[TMBORange class]]);
            
            // Uploads newer than anything else in self.items
            NSUInteger tableTop = [[[self.items objectAtIndex:0] uploadid] integerValue];
            NSUInteger insertionIndex = 0;
            
            while ([uploads count] && [[[uploads objectAtIndex:0] uploadid] integerValue] > tableTop) {
                // Add to top of items array
                TMBOUpload *upload = [uploads objectAtIndex:0];
                [uploads removeObjectAtIndex:0];
                
                [upload addObserver:self forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionNew context:kUploadThumbnailContext];
                [upload addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:kUploadCommentsContext];
                [self.items insertObject:upload atIndex:insertionIndex++];
                offset.y += self.tableView.rowHeight;
            }
            
            if (![uploads count]) {
                // Ran out of uploads before hitting pre-existing top of list, add a range
                Assert([[self.items objectAtIndex:insertionIndex - 1] isKindOfClass:[TMBOUpload class]]);
                Assert([[self.items objectAtIndex:insertionIndex] isKindOfClass:[TMBOUpload class]]);
                NotTested();
                
                NSUInteger first = [[[self.items objectAtIndex:insertionIndex] uploadid] integerValue];
                NSUInteger last = [[[self.items objectAtIndex:insertionIndex - 1] uploadid] integerValue];
                [self.items insertObject:[TMBORange rangeWithFirst:first last:last] atIndex:insertionIndex];
                offset.y += self.tableView.rowHeight;
            }
            
            for (; insertionIndex < [self.items count] && [uploads count]; insertionIndex++) {
                // Add new uploads to the range objects of the table
                if (![[self.items objectAtIndex:insertionIndex] isKindOfClass:[TMBORange class]]) continue;
                TMBORange *range = [self.items objectAtIndex:insertionIndex];
                
                // Remove objects outside of the range
                while ([uploads count] && [[[uploads objectAtIndex:0] uploadid] integerValue] > range.last) {
                    [uploads removeObjectAtIndex:0];
                }
                if (![uploads count]) break;
                
                NSUInteger newestUpload = [[[uploads objectAtIndex:0] uploadid] integerValue];
                if (newestUpload < range.last) {
                    // New Uploads are within range, but do not overlap on the newer side. Split the range.
                    NotTested();
                    // It shouldn't be possible for this to happen when loading at the bottom of the table
                    Assert(range.first > kFirstUploadID);
                    [self.items insertObject:[TMBORange rangeWithFirst:range.first last:newestUpload] atIndex:insertionIndex++];
                    offset.y += self.tableView.rowHeight;
                } else if (newestUpload == range.last) {
                    [uploads removeObjectAtIndex:0];
                }
                if (![uploads count]) break;
                
                while ([uploads count] && [[[uploads objectAtIndex:0] uploadid] integerValue] > range.first) {
                    TMBOUpload *upload = [uploads objectAtIndex:0];
                    NSUInteger uploadid = [[upload uploadid] integerValue];
                    [uploads removeObjectAtIndex:0];
                    
                    [upload addObserver:self forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionNew context:kUploadThumbnailContext];
                    [upload addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:kUploadCommentsContext];
                    [self.items insertObject:upload atIndex:insertionIndex];
                    // Add to offset only if not loading at the bottom
                    if (range.first > kFirstUploadID) offset.y += self.tableView.rowHeight;
                    
                    // Consistency check: previous range should have been set by code above
                    if ([[self.items objectAtIndex:insertionIndex - 1] isKindOfClass:[TMBORange class]]) {
                        NotTested();
                        Assert([[self.items objectAtIndex:insertionIndex - 1] last] == uploadid);
                    }
                    Assert([[self.items objectAtIndex:insertionIndex + 1] isKindOfClass:[TMBORange class]]);
                    Assert([[self.items objectAtIndex:insertionIndex + 1] isEqual:range]);
                    range.last = uploadid;
                    insertionIndex++;
                }
                if (range.first == range.last) {
                    Assert([[self.items objectAtIndex:insertionIndex] isKindOfClass:[TMBORange class]]);
                    Assert([[self.items objectAtIndex:insertionIndex] isEqual:range]);
                    [self.items removeObjectAtIndex:insertionIndex];
                    // If a range is exhausted, we've either hit the beginning of time or (more likely) exhausted an interim range
                    Assert(range.first == kFirstUploadID || [[self.items objectAtIndex:insertionIndex] isKindOfClass:[TMBOUpload class]]);
                }
            }
        }
        
#ifdef DEBUG
        for (int i = 1; i < [self.items count] - 1; i++) {
            id item = [self.items objectAtIndex:i];
            id higher = [self.items objectAtIndex:i - 1];
            id lower = [self.items objectAtIndex:i + 1];
            
            if ([item isKindOfClass:[TMBOUpload class]]) {
                if ([higher isKindOfClass:[TMBOUpload class]]) {
                    Assert([[higher uploadid] integerValue] > [[item uploadid] integerValue]);
                } else {
                    Assert([higher isKindOfClass:[TMBORange class]]);
                    Assert([higher first] == [[item uploadid] integerValue]);
                }
                
                if ([lower isKindOfClass:[TMBOUpload class]]) {
                    Assert([[lower uploadid] integerValue] < [[item uploadid] integerValue]);
                } else {
                    Assert([lower isKindOfClass:[TMBORange class]]);
                    Assert([lower last] == [[item uploadid] integerValue]);
                }
            } else if ([item isKindOfClass:[TMBORange class]]) {
                Assert([higher isKindOfClass:[TMBOUpload class]]);
                Assert([lower isKindOfClass:[TMBOUpload class]]);
                Assert([[higher uploadid] integerValue] == [item last]);
                Assert([[lower uploadid] integerValue] == [item first]);
            }
        }
#endif
        
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
