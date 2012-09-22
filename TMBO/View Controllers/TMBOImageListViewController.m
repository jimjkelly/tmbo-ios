//
//  TMBOImageListViewController.m
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOImageListViewController.h"

#import <CoreData/CoreData.h>
#import <UIImageView+AFNetworking.h>

#import "TMBOImageListCell.h"
#import "TMBOImageDetailViewController.h"
#import "TMBOJSONRequestOperation.h"
#import "TMBOLoadingCell.h"
#import "TMBOUpload.h"
#import "UIImage+Resize.h"

@interface TMBOImageListViewController () <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *_fetchedResultsController;
    UIRefreshControl *_topRefresh;
}
- (void)refetchData;
@end

@implementation TMBOImageListViewController

- (void)refetchData;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_topRefresh beginRefreshing];
        [_fetchedResultsController performFetch:nil];
    });
}

/* HACK: This is a goddamn hack.
 * The intent is to [_topRefresh endRefreshing] when the server data arrives and is processed by Core Data,
 * but there's no notification that corresponds to that specific event and not a different model request.
 * The next closest thing is to use controllerDidChangeContent, but that's not good enough—if the server data indicates no changes, the callback never happens.
 * This will at least always reset the refreshing status of the table, if not a bit prematurely.
 */
- (void)notification:(NSNotification *)note;
{
    if ([[note object] isKindOfClass:[TMBOJSONRequestOperation class]]) {
        [_topRefresh endRefreshing];
    }
}

#pragma mark - UITableViewController

// HACK: this is part of the hack described above
- (void)viewWillAppear:(BOOL)animated;
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:@"com.alamofire.networking.operation.finish" object:nil];
}

// HACK: this is part of the hack described above
- (void)viewWillDisappear:(BOOL)animated;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Upload"];
    // WHERE type = image pls
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"uploadid" ascending:NO]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"type = \"image\""];
    fetchRequest.fetchLimit = 50;
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[(id)[[UIApplication sharedApplication] delegate] managedObjectContext] sectionNameKeyPath:nil cacheName:@"ImageStream"];
    _fetchedResultsController.delegate = self;
    [self refetchData];
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refetchData)];
    
    UINib *nib = [UINib nibWithNibName:@"TMBOImageListCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"TMBOImageListCell"];
    nib = [UINib nibWithNibName:@"TMBOLoadingCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"TMBOLoadingCell"];
    
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
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [[[_fetchedResultsController sections] objectAtIndex:section] numberOfObjects] + 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0 && indexPath.row == [[[_fetchedResultsController sections] objectAtIndex:indexPath.section] numberOfObjects]) {
        static NSString *LoadingCellIdentifier = @"TMBOLoadingCell";
        cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:LoadingCellIdentifier];
        [[(TMBOLoadingCell *)cell spinner] startAnimating];
    } else {
        static NSString *ImageCellIdentifier = @"TMBOImageListCell";
        cell = [tableView dequeueReusableCellWithIdentifier:ImageCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ImageCellIdentifier];
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)uitvcell
          atIndexPath:(NSIndexPath *)indexPath
{
    TMBOImageListCell *cell = (TMBOImageListCell *)uitvcell;
    @try {
        TMBOUpload *upload = (TMBOUpload *)[_fetchedResultsController objectAtIndexPath:indexPath];
        
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
                        NSIndexPath *path = [_fetchedResultsController indexPathForObject:upload];
                        TMBOImageListCell *validCell = (TMBOImageListCell *)[self.tableView cellForRowAtIndexPath:path];
                        
                        if (validCell) {
                            [[validCell spinner] stopAnimating];
                            if (![upload filtered]) {
                                [[validCell thumbnailView] setImage:image];
                            }
                            [validCell setNeedsDisplay];
                        }
                    }
                    failure:^( NSURLRequest *request , NSHTTPURLResponse *response , NSError *error ){
                        NSIndexPath *path = [_fetchedResultsController indexPathForObject:upload];
                        TMBOImageListCell *validCell = (TMBOImageListCell *)[self.tableView cellForRowAtIndexPath:path];

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
    [detailViewController setUpload:(TMBOUpload *)[_fetchedResultsController objectAtIndexPath:indexPath]];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSUInteger)supportedInterfaceOrientations;
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

#pragma mark Target-action for UIRefreshControl

- (void)refreshControlEvent:(UIRefreshControl *)something;
{
    [self refetchData];
}

@end
