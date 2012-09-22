//
//  TMBOAppDelegate.h
//  TMBO
//
//  Created by Scott Perry on 09/19/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMBOAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
