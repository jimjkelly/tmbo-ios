//
//  TMBORange.h
//  TMBO
//
//  Created by Scott Perry on 10/07/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMBORange : NSObject
@property (nonatomic, assign) NSInteger first;
@property (nonatomic, assign) NSInteger last;

- (id)initWithFirst:(NSInteger)first last:(NSInteger)last;
@end
