//
//  AppDelegate.h
//  FBAuto
//
//  Created by 史忠坤 on 14-6-25.
//  Copyright (c) 2014年 szk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,UITabBarDelegate,UITabBarControllerDelegate>
{
//    UIWindow *statusBarBack;
}

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,retain)UILabel *messageLabel;//消息条数

@property (nonatomic,retain)UIWindow *statusBarBack;


@property (nonatomic,retain)Reachability *hostReach;//网络监控
@property (nonatomic,assign)BOOL isReachable;//在其他页面可根据此判断当前网络是否可用

@property (nonatomic,retain)NSDictionary *pushUserInfo;//推送消息

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
