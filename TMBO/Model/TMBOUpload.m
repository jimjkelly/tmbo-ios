//
//  TMBOUpload.m
//  TMBO
//
//  Created by Scott Perry on 09/26/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOUpload.h"

#import "NNLIFOOperationQueue.h"
#import "TMBOAPIClient.h"
#import "UIImage+Resize.h"

NSComparator kUploadComparator = ^(id a, id b) {
    Assert([a isKindOfClass:[TMBOUpload class]]);
    Assert([b isKindOfClass:[TMBOUpload class]]);
    Assert([[a uploadid] unsignedIntegerValue] != [[b uploadid] unsignedIntegerValue]);
    // Reverse sort: lower indexes are higher uploads
    return [[b uploadid] compare:[a uploadid]];
};

static NNLIFOOperationQueue *thumbnailOperationQueue;

@implementation TMBOUpload

@dynamic badVotes;
@dynamic comments;
@dynamic filename;
@dynamic fileURL;
@dynamic filtered;
@dynamic goodVotes;
@dynamic height;
@dynamic lastActive;
@dynamic nsfw;
@dynamic repostVotes;
@dynamic subscribed;
@dynamic thumbnailData;
@dynamic thumbURL;
@dynamic timestamp;
@dynamic tmbo;
@dynamic tmboVotes;
@dynamic type;
@dynamic uploadid;
@dynamic userid;
@dynamic username;
@dynamic width;

@synthesize thumbnail = _thumbnail;

+ (void)initialize;
{
    thumbnailOperationQueue = [[NNLIFOOperationQueue alloc] init];
}

- (UIImage *)thumbnail;
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

+ (Class)typeFor:(NSString *)varname;
{
    static NSDictionary *typearray = nil;
    
    if (!typearray) {
        @synchronized(self) {
            if (!typearray) {
                typearray = @{@"badVotes" : [NSNumber class],
                @"comments" : [NSNumber class],
                @"filename" : [NSString class],
                @"fileURL" : [NSString class],
                @"filtered" : [NSNumber class],
                @"goodVotes" : [NSNumber class],
                @"height" : [NSNumber class],
                @"lastActive" : [NSDate class],
                @"nsfw" : [NSNumber class],
                @"repostVotes" : [NSNumber class],
                @"subscribed" : [NSNumber class],
                @"thumbnailData" : [NSData class],
                @"thumbURL" : [NSString class],
                @"timestamp" : [NSDate class],
                @"tmbo" : [NSNumber class],
                @"tmboVotes" : [NSNumber class],
                @"type" : [NSString class],
                @"uploadid" : [NSNumber class],
                @"userid" : [NSNumber class],
                @"username" : [NSString class],
                @"width" : [NSNumber class]};
            }
        }
    }
    
    return [typearray objectForKey:varname];
}

- (kTMBOType)kindOfUpload;
{
    if ([self.type isEqualToString:@"image"]) {
        return kTMBOTypeImage;
    } else if ([self.type isEqualToString:@"topic"]) {
        return kTMBOTypeTopic;
    } else if ([self.type isEqualToString:@"avatar"]) {
        return kTMBOTypeAvatar;
    } else if ([self.type isEqualToString:@"audio"]) {
        return kTMBOTypeAudio;
    }
    NotReached();
    return kTMBOTypeAny;
}

- (void)refreshThumbnailWithMinimumSize:(CGSize)thumbsize;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // TODO: check this!
        // Thumbnail is not good enough. Load another!
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kTMBOBaseURLString, self.thumbURL]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            Assert([responseObject isKindOfClass:[NSData class]]);
            if ([responseObject isKindOfClass:[NSData class]]) {
                UIImage *image = [UIImage imageWithData:responseObject];
                UIImage *thumb = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:thumbsize interpolationQuality:kCGInterpolationHigh];
                
                if (!thumb) {
                    // TODO: this works, but it sucks.
                    Log(@"Failed to resize thumbnail image! Falling back to using the upload directly.");
                }
                
                // Causes a KVO notification. If a cell is currently displaying this upload, it will be updated.
                self.thumbnail = thumb ?: image;
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Causes a KVO notification. If a cell is currently displaying this upload, it will be updated.
            self.thumbnail = nil;
            Log(@"%@ encountered error: %@", operation, error);
        }];
        
        [thumbnailOperationQueue addOperation:operation forKey:self.thumbURL];
    });
}

- (void)getFileWithSuccess:(void ( ^ ) ( AFHTTPRequestOperation *operation , id responseObject ))success
                   failure:(void ( ^ ) ( AFHTTPRequestOperation *operation , NSError *error ))failure
                  progress:(void ( ^ ) ( NSUInteger bytesRead , long long totalBytesRead , long long totalBytesExpectedToRead ))progress;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *errorString;
        void(^bail)(void) = ^{
            if (failure)
                failure(nil, [NSError errorWithDomain:@"FIXMEDomain" code:42 userInfo:@{ @"FIXME" : errorString }]);
        };
        
        errorString = @"Upload type does not have a backing file";
        BailWithBlockUnless([self kindOfUpload] & ~kTMBOTypeTopic, bail);
        errorString = @"Upload does not have a backing file";
        BailWithBlockUnless(self.fileURL, bail);
        
        NSURLRequest *request = [[TMBOAPIClient sharedClient] requestWithMethod:@"GET" path:self.fileURL parameters:nil];
        Assert(request);
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:success failure:failure];
        [operation setDownloadProgressBlock:progress];
        
        [operation start];
    });
}

#pragma mark - TMBOObject

- (NSInteger)objectid;
{
    Assert(self.uploadid);
    return [self.uploadid integerValue];
}

@end
