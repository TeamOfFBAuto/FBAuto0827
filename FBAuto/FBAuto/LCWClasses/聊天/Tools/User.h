//
//  User.h
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  用户
 */
@interface User : NSObject
@property(nonatomic,retain)NSString *userName;
@property(nonatomic,retain)NSString *presentType;//状态

@property(nonatomic,retain)id jid;
@property(nonatomic,retain)NSString *subscription;
@property(nonatomic,retain)NSString *groupName;

-(id)initWithName:(NSString *)name type:(NSString *)type;

-(id)initWithName:(NSString *)name jid:(id)jid subscription:(NSString *)subscription groupName:(NSString *)groupName;

@end
