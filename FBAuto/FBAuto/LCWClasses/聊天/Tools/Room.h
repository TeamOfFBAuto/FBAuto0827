//
//  Room.h
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-26.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  聊天室
 */
@interface Room : NSObject

@property(nonatomic,retain)NSString *name;
@property(nonatomic,retain)NSString *jid;//状态

-(id)initWithName:(NSString *)name jid:(NSString *)jid;

@end
