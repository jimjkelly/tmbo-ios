//
//  TMBOUpload.m
//  TMBO
//
//  Created by Scott Perry on 09/21/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "TMBOUpload.h"


@implementation TMBOUpload

@dynamic uploadid;
@dynamic userid;
@dynamic filename;
@dynamic timestamp;
@dynamic nsfw;
@dynamic tmbo;
@dynamic type;
@dynamic subscribed;
@dynamic goodVotes;
@dynamic badVotes;
@dynamic tmboVotes;
@dynamic repostVotes;
@dynamic comments;
@dynamic filtered;
@dynamic lastActive;
@dynamic fileURL;
@dynamic width;
@dynamic height;
@dynamic thumbURL;
@dynamic thumbnailData;
@dynamic username;

@synthesize thumbnail = _thumbnail;

- (UIImage *)thumbnail
{
    if (!self.thumbnailData) return nil;
    
    if (!_thumbnail) {
        _thumbnail = [UIImage imageWithData:self.thumbnailData];
    }
    return _thumbnail;
}

- (void)setThumbnail:(UIImage *)image;
{
    UIImage *smallImage = image;
    _thumbnail = smallImage;
    self.thumbnailData = UIImageJPEGRepresentation(smallImage, 0.8);
}

@end
