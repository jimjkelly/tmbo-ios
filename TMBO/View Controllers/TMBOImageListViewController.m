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
#import "TMBOUpload.h"
#import "UIImage+Resize.h"

@interface TMBOImageListViewController () <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *_fetchedResultsController;
}
- (void)refetchData;
@end

@implementation TMBOImageListViewController

- (void)refetchData;
{
    [_fetchedResultsController performSelectorOnMainThread:@selector(performFetch:) withObject:nil waitUntilDone:YES modes:@[ NSRunLoopCommonModes ]];
}

#pragma mark - UITableViewController

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
    fetchRequest.fetchLimit = 50;
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[(id)[[UIApplication sharedApplication] delegate] managedObjectContext] sectionNameKeyPath:nil cacheName:@"ImageStream"];
    _fetchedResultsController.delegate = self;
    [self refetchData];
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refetchData)];
    
    UINib *nib = [UINib nibWithNibName:@"TMBOImageListCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"TMBOImageListCell"];
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
    return [[[_fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
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
        
        // Compute ideal thumbnail size in pixels (not points)
        CGSize thumbsize = [[cell thumbnailView] bounds].size;
        thumbsize.width *= [[UIScreen mainScreen] scale];
        thumbsize.height *= [[UIScreen mainScreen] scale];
        
        UIImage *thumbnail = [upload thumbnail];
        if (thumbnail) {
            [[cell thumbnailView] setImage:thumbnail];
        }
        if ([upload thumbURL] && (!thumbnail || [thumbnail size].height < thumbsize.height || [thumbnail size].width < thumbsize.width)) {
            // Thumbnail is not good enough. Load another!
            NSURL *thumbURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://thismight.be%@", [upload thumbURL]]];
            NSURLRequest *req = [NSURLRequest requestWithURL:thumbURL cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:60.0];
            [[cell thumbnailView] setImageWithURLRequest:req
                                    placeholderImage:nil
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 UIImage *thumb = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:thumbsize interpolationQuality:kCGInterpolationHigh];
                                                 [upload setThumbnail:thumb];
//                                                 [cell thumbnailView] setImage:<#(UIImage *)#>
                                                 [[cell spinner] stopAnimating];
                                                 [cell setNeedsDisplay];
                                             }
                                             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                 NSLog(@"Error getting thumbnail: %@ (%@)", error, [error localizedDescription]);
                                                 [[cell spinner] stopAnimating];
                                                 [cell setNeedsDisplay];
                                             }];
        }
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
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
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

@end
