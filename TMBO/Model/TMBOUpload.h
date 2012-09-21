//
//  TMBOUpload.h
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
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

@end
