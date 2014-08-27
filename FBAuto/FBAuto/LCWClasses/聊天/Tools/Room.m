//
//  Room.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-26.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "Room.h"

@implementation Room

-(id)initWithName:(NSString *)name jid:(NSString *)jid
{
    self = [super init];
    
    if (self) {
        self.name = name;
        self.jid = jid;
    }
    return self;
}

@end
