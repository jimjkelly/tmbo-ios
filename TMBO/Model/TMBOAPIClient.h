//
//  TMBOAPIClient.h
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "AFRESTClient.h"

@interface TMBOAPIClient : AFRESTClient <AFIncrementalStoreHTTPClient>
+ (TMBOAPIClient *)sharedClient;
@end
