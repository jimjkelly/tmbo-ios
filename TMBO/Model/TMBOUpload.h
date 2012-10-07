//
//  TMBOUpload.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSComparator kUploadComparator;

typedef enum : NSUInteger {
    kTMBOTypeImage  = 0x1,
    kTMBOTypeTopic  = 0x2,
    kTMBOTypeAudio  = 0x4,
    kTMBOTypeAvatar = 0x8,
    kTMBOTypeAny    = kTMBOTypeImage | kTMBOTypeTopic | kTMBOTypeAudio | kTMBOTypeAvatar
} kTMBOType;

@interface TMBOUpload : NSManagedObject

@property (nonatomic, retain) NSNumber * badVotes;
@property (nonatomic, retain) NSNumber * comments;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * fileURL;
@property (nonatomic, retain) NSNumber * filtered;
@property (nonatomic, retain) NSNumber * goodVotes;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSDate * lastActive;
@property (nonatomic, retain) NSNumber * nsfw;
@property (nonatomic, retain) NSNumber * repostVotes;
@property (nonatomic, retain) NSNumber * subscribed;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSString * thumbURL;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * tmbo;
@property (nonatomic, retain) NSNumber * tmboVotes;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * uploadid;
@property (nonatomic, retain) NSNumber * userid;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * width;

@property (nonatomic, retain) UIImage *thumbnail;

// TODO: - (TMBOUpload *)prev;
// TODO: - (TMBOUpload *)next;

+ (Class)typeFor:(NSString *)varname;
- (kTMBOType)kindOfUpload;

- (void)refreshThumbnailWithMinimumSize:(CGSize)thumbsize;

@end
