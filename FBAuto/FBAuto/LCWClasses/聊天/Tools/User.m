//
//  User.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "User.h"

@implementation User

-(id)initWithName:(NSString *)name type:(NSString *)type
{
    self = [super init];
    
    if (self) {
        self.userName = name;
        self.presentType = type;
    }
    return self;
}

-(id)initWithName:(NSString *)name jid:(id)jid subscription:(NSString *)subscription groupName:(NSString *)groupName
{
    self = [super init];
    if (self) {
        self.userName = name;
        self.jid = jid;
        self.subscription = subscription;
        self.groupName = groupName;
    }
    return self;
}

@end
