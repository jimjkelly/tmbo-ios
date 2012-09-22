//
//  TMBOUpload.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TMBOUpload : NSManagedObject

@property (nonatomic) int32_t uploadid;
@property (nonatomic) int32_t userid;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic) BOOL nsfw;
@property (nonatomic) BOOL tmbo;
@property (nonatomic, retain) NSString * type;
@property (nonatomic) BOOL subscribed;
@property (nonatomic) int32_t goodVotes;
@property (nonatomic) int32_t badVotes;
@property (nonatomic) int32_t tmboVotes;
@property (nonatomic) int32_t repostVotes;
@property (nonatomic) int32_t comments;
@property (nonatomic) BOOL filtered;
@property (nonatomic, retain) NSDate *lastActive;
@property (nonatomic, retain) NSString * fileURL;
@property (nonatomic) int32_t width;
@property (nonatomic) int32_t height;
@property (nonatomic, retain) NSString * thumbURL;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSString * username;

@property (nonatomic, retain) UIImage *thumbnail;

@end
