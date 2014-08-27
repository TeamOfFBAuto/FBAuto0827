//
//  XMPPServer.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "XMPPServer.h"

#import "FBCityData.h"

/**
 *  先建立连接，然后进行秘密验证，验证通过后上线
 */

/**
 *  jid中得用户名 test@localhost 格式
 *  默认端口 5222,否则可能会报错:认证错误
 *
 *  发送对象格式:user@地址,否则对方接收不到消息
 *
 **
 */

@implementation XMPPServer
{
    NSString *PWD;
    BOOL isOpen;
}

+(id)shareInstance
{
    static dispatch_once_t once_t;
    static XMPPServer *xmpp = nil;
    dispatch_once(&once_t, ^{
        xmpp = [[XMPPServer alloc]init];
    });
    return  xmpp;
}

//设置XMPPStream
-(void)setupStream
{
    self.xmppStream = [[XMPPStream alloc]init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _xmppStream.enableBackgroundingOnSocket = YES;//允许后台模式
    
    //重连接
    
    self.xmppReconnect = [[XMPPReconnect alloc]init];
    [_xmppReconnect activate:_xmppStream];
    [_xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    //花名册
    
    self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    
    if (_xmppRosterStorage == nil) {
        _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc]init];
    }
	
	self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    [_xmppRoster activate:_xmppStream];
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _xmppRoster.autoFetchRoster = YES;
    
    
    self.xmppMessageArchivingCoreDataStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    self.xmppMessageArchivingModule = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage];
    [_xmppMessageArchivingModule setClientSideMessageArchivingOnly:YES];
    [_xmppMessageArchivingModule activate:_xmppStream];
    [_xmppMessageArchivingModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    //验证密码使用
    
    self.xmppPlainAutentication = [[XMPPPlainAuthentication alloc]initWithStream:[self xmppStream] password:PWD];
}

//是否连接

-(BOOL)connect
{
    [self setupStream];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *userName = [defaults objectForKey:XMPP_USERID];
    NSString *passWord = [defaults objectForKey:XMPP_PASS];
    NSString *server = [defaults objectForKey:XMPP_SERVER];
//    NSString *jid = [defaults objectForKey:XMPP_JID];
    
    NSLog(@"md5 password %@",passWord);
    
    
    //判断是否断开，没有返回yes
    if ([_xmppStream isDisconnected] == NO) {
        return YES;
    }
    if (userName == nil || passWord == nil) {
        
        return NO;
    }
    
    //jid格式为 userName@host  否则不可用
    NSString *jidName = [NSString stringWithFormat:@"%@@%@",userName,server];
    
    NSLog(@"jidName %@",jidName);
    
    [_xmppStream setMyJID:[XMPPJID jidWithString:jidName]];
    [_xmppStream setHostName:server];
    PWD = passWord;
    
    //连接服务器
    
    NSError *erro;
    BOOL isConnect = [_xmppStream connectWithTimeout:10 error:&erro];
    if (!isConnect) {
        
        NSLog(@"can't connect %@ erro %@",server,erro);
        return NO;
    }
    
    return YES;
    
}

//断开连接

-(void)disconnect
{
    [self goOffline];//下线
    [_xmppStream disconnect];//断开连接
}

//上线

-(void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream]sendElement:presence];
    
    //更新最近登陆时间
}

//下线

-(void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream]sendElement:presence];
    
    //更新下线时间
}

#pragma - mark 登录

- (void)login:(loginAction)login_Back
{
    loginBack = login_Back;
    
    [self connect];
}

static int x = 10;


- (void)time:(NSString *)time
{
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy年MM月dd日"];
    NSDate *date = [outputFormatter dateFromString:time];
    
    NSLog(@"testDate:%@", date);
}

#pragma mark - 登录

- (void)sendMessage:(NSString *)messageText toUser:(NSString *)userPhone shareLink:(NSString *)shareLink messageBlock:(MessageAction)messageBlock
{
    message_Back = messageBlock;
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageText];
    
    //生成XML消息文档
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    //消息类型
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    //发送给谁
    [mes addAttributeWithName:MESSAGE_SHATE_LINK stringValue:shareLink];
    NSString *toUser = [NSString stringWithFormat:@"%@@%@",userPhone,[[NSUserDefaults standardUserDefaults] stringForKey:XMPP_SERVER]];
    
    //聊天对象nickName
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *senderName = [defaults objectForKey:USERNAME];
    NSString *senderId = [defaults objectForKey:USERID];
    
    [mes addAttributeWithName:@"senderName" stringValue:senderName ? senderName : @""];
    [mes addAttributeWithName:@"senderId" stringValue:senderId ? senderId : @""];
    [mes addAttributeWithName:@"to" stringValue:toUser];
    
    //由谁发送
    [mes addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults] stringForKey:XMPP_USERID]];
    //组合
    [mes addChild:body];
    
    //发送消息
    [[self xmppStream] sendElement:mes];
}

- (void)loginTimes:(int)times loginBack:(loginAction)login_Back//多次联系登录
{
    loginBack = login_Back;
    
    if ([self.xmppStream isAuthenticated])
    {
        login_Back(YES);
        return;
    }
    
        [[XMPPServer shareInstance]login:^(BOOL result) {
            if (result) {
                NSLog(@"连接并且登录成功");
                
                login_Back(YES);
                
                x = 10;
                
                return ;
            }else
            {
                
                NSLog(@"连接登录不成功");
                
                x --;
                
                if (x >= 0) {
                    
                    [self loginTimes:0 loginBack:login_Back];
                }else
                {
                    login_Back(NO);
                    x = 10;
                }
                
            }
        }];

}

#pragma - mark 查询已存在房间

- (void)getExistRooms:(roomBackBlock)roomBack
{
    callBack = roomBack;
    NSXMLElement *queryElement= [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/disco#items"];
    NSXMLElement *iqElement = [NSXMLElement elementWithName:@"iq"];
    [iqElement addAttributeWithName:@"type" stringValue:@"get"];
    [iqElement addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:XMPP_JID]];
    [iqElement addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"conference.%@",[[NSUserDefaults standardUserDefaults]objectForKey:XMPP_SERVER]]];
    [iqElement addAttributeWithName:@"id" stringValue:@"getexistroomid"];
    [iqElement addChild:queryElement];
    NSLog(@"已存在房间:%@",iqElement);
    [self.xmppStream sendElement:iqElement];
}



#pragma - mark  XMPPStreamDelegate 连接代理

- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
    NSLog(@"xmppStreamWillConnect");
}

//连接服务器
- (void)xmppStreamDidConnect:(XMPPStream *)sender{
    
    isOpen = YES;
    NSError *error = nil;
    //验证密码
    
    //验证最好使用以下方法,上述方法可能被弃用
    
    [[self xmppStream]authenticate:_xmppPlainAutentication error:nil];
    
    NSLog(@"authenticate Erro %@",error);
}

//验证通过
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    
    NSLog(@"xmppStreamDidAuthenticate");
    
    [self goOnline];
    
    if (loginBack) {
        loginBack(YES);
    }
    NSLog(@"------------------");
    [_xmppRoster fetchRoster];
}

//验证未通过
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"didNotAuthenticate: %@",error);
    
    if (loginBack) {
        loginBack(NO);
    }
}

//监控消息接收
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"message = %@", message);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *msg = [[message elementForName:@"body"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    
    //接受者
//    NSString *status = [[message attributeForName:@"status"]stringValue];//是否是离线消息
    NSString *senderName = [[message attributeForName:@"senderName"]stringValue];//发送者 nickName
    NSString *senderId = [[message attributeForName:@"senderId"]stringValue];//接收者nickName
    
    NSString *currentUserPhone = [defaults objectForKey:XMPP_USERID];
    
    //判断是否离线
    
    NSArray *delay = [message elementsForName:@"delay"];
    
    NSArray *fromArr = [from componentsSeparatedByString:@"@"];
    
    NSString *fromPhone = @"";
    
    if (fromArr.count > 0) {
        fromPhone = [fromArr objectAtIndex:0];
    }
    //离线消息
    if (delay.count > 0) {
        
        NSString *delayTime = [[[delay objectAtIndex:0]attributeForName:@"stamp"]stringValue];
        delayTime = [delayTime substringToIndex:10];
        NSLog(@"delay %@",delayTime);
        
        [FBCityData updateCurrentUserPhone:currentUserPhone fromUserPhone:fromPhone fromName:senderName fromId:senderId newestMessage:msg time:delayTime clearReadSum:NO];
    }else
    {
        NSString *chatingUser = [defaults objectForKey:CHATING_USER];
        
        BOOL needClear = NO;
        
        //如果是当前正在聊得人,则未读计数清为0
        if ([chatingUser isEqualToString:fromPhone]) {
            needClear = YES;
        }
        
        [FBCityData updateCurrentUserPhone:currentUserPhone fromUserPhone:fromPhone fromName:senderName fromId:senderId newestMessage:msg time:[LCWTools currentTime] clearReadSum:needClear];
    }
    
    //发送未读消息通知
    [[NSNotificationCenter defaultCenter]postNotificationName:@"unReadNumber" object:nil];
    
    if(msg)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:msg forKey:@"msg"];
        [dict setObject:from forKey:@"sender"];
        //消息接收到的时间
        [dict setObject:[XMPPStatics getCurrentTime] forKey:@"time"];
        
        //消息委托(这个后面讲)
        
        if (self.messageDelegate && [_messageDelegate respondsToSelector:@selector(newMessage:)]) {
            [_messageDelegate newMessage:dict];
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    NSLog(@"didSendMessage");
    message_Back(nil,1);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    NSLog(@"didFailToSendMessage %@",error);
    message_Back(nil,0);;
}

//监控好友状态
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"presence = %@", presence);
    
    //取得好友状态
    NSString *presenceType = [presence type]; //online/offline
    NSString *show = [presence show];//away
    NSString *status = [presence status];//离开
    
    NSLog(@"\n presenceType:%@\n show:%@ \n status:%@\n",presenceType,show,status);
    
    //当前用户
    NSString *userId = [[sender myJID] user];
    //在线用户
    NSString *presenceFromUser = [[presence from] user];
    
    if (![presenceFromUser isEqualToString:userId]) {
    
        //用户上线
        
        if ([presenceType isEqualToString:@"available"]) {
            //包含在线和不在线
            if (self.chatDelegate && [_chatDelegate respondsToSelector:@selector(userOnline:)]) {
                User *aUser = [[User alloc]initWithName:presenceFromUser type:presenceType];
                [_chatDelegate userOnline:aUser];
                
                [[NSUserDefaults standardUserDefaults]setObject:@"online" forKey:aUser.userName];
                [[NSUserDefaults standardUserDefaults]synchronize];
                
                NSLog(@"line state %@ online",aUser.userName);
            }
        }
        
        //用户下线
        
        else if ([presenceType isEqualToString:@"unavailable"])
        {
            if (self.chatDelegate && [_chatDelegate respondsToSelector:@selector(userOffline:)]) {
                User *aUser = [[User alloc]initWithName:presenceFromUser type:presenceType];
                [_chatDelegate userOffline:aUser];
                
                [[NSUserDefaults standardUserDefaults]setObject:@"offline" forKey:aUser.userName];
                [[NSUserDefaults standardUserDefaults]synchronize];
                
                NSLog(@"line state %@ offline",aUser.userName);
                
                //http://localhost:9090/plugins/presence/status?jid=18612389982@localhost&type=xml
            }

        }
        
        //这里再次加好友:如果请求的用户返回的是同意添加
        else if ([presenceType isEqualToString:@"subscribed"]) {
            XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@",[presence from]]];
//            [[XMPPServer xmppRoster] acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
            NSLog(@"subscribed %@",jid);
        }
        
        //用户拒绝添加好友
        else if ([presenceType isEqualToString:@"unsubscribed"]) {
            //TODO
            XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@",[presence from]]];
            NSLog(@"unsubscribed %@",jid);
        }
    }
}

#pragma - mark 好友相关处理

//获取好友列表、以及已存在房间

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{

    
    NSLog(@"didReceiveIQ--iq is:%@",iq.XMLString);
    
    //房间列表
    
    if (callBack) {
        callBack(iq);
    }
    
    
    //好友列表
    
    if ([@"result" isEqualToString:iq.type]) {
        
        NSXMLElement *query = iq.childElement;
        
        if ([@"query" isEqualToString:query.name]) {
            
            NSMutableArray *userArray = [NSMutableArray array];
            
            NSArray *items = [query children];
            
            for (NSXMLElement *item in items) {
                //订阅签署状态
                NSString *subscription = [item attributeStringValueForName:@"subscription"];
                
//                if ([subscription isEqualToString:@"both"]) { //互相加好友
                
                    NSString *jid = [item attributeStringValueForName:@"jid"];
                    NSString *name = [item attributeStringValueForName:@"name"];
                    //分组（例如:联系人列表、好友列表）
                    NSArray *groups = [item elementsForName:@"group"];
                    
                    User *aUser = [[User alloc]initWithName:name jid:jid subscription:subscription groupName:Nil];
                    
                    for (NSXMLElement *groupElement in groups) {
                        NSString *groupName = groupElement.stringValue;
                        
                        NSLog(@"didReceiveIQ----xmppJID:%@ , in group:%@",jid,groupName);
                        
                        
                        aUser.groupName = (groupName != Nil) ? groupName : @"";
                        
                        
                    }
                
                    [userArray addObject:aUser];
//                }
            
            }
            
            if (self.chatDelegate && [_chatDelegate respondsToSelector:@selector(friendsArray:)]) {
                
                [_chatDelegate friendsArray:userArray];
            }
        }
    }
    return YES;
}


#pragma mark - XMPPRoster delegate
/*
 *  好友添加请求
 */
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
    //好友状态
    NSString *presenceType = [NSString stringWithFormat:@"%@", [presence type]];
    //请求的用户
    NSString *presenceFromUser =[NSString stringWithFormat:@"%@", [[presence from] user]];
    
    NSLog(@"didReceivePresenceSubscriptionRequest----presenceType:%@,用户：%@,presence:%@",presenceType,presenceFromUser,presence);
    
    
    XMPPJID *jid = [XMPPJID jidWithString:presenceFromUser];
    [self.xmppRoster  acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
    
    /*
     user1向登录账号user2请求加为好友：
     
     presenceType:subscribe
     presence2:<presence xmlns="jabber:client" to="user2@chtekimacbook-pro.local" type="subscribe" from="user1@chtekimacbook-pro.local"/>
     sender2:<XMPPRoster: 0x7c41450>
     
     登录账号user2发起user1好友请求，user5
     presenceType:subscribe
     presence2:<presence xmlns="jabber:client" type="subscribe" to="user2@chtekimacbook-pro.local" from="user1@chtekimacbook-pro.local"/>
     sender2:<XMPPRoster: 0x14ad2fb0>
     */
}

/**
 * Sent when a Roster Push is received as specified in Section 2.1.6 of RFC 6121.
 *
 * 添加好友、好友确认、删除好友
 
 //请求添加user6@chtekimacbook-pro.local 为好友
 <iq xmlns="jabber:client" type="set" id="880-334" to="user2@chtekimacbook-pro.local/f3e9c656">
 <query xmlns="jabber:iq:roster">
 <item jid="user6@chtekimacbook-pro.local" ask="subscribe" subscription="none"/>
 </query>
 </iq>
 
 //用户6确认后：
 <iq xmlns="jabber:client" type="set" id="880-334" to="user2@chtekimacbook-pro.local/662d302c"><query xmlns="jabber:iq:roster"><item jid="user6@chtekimacbook-pro.local" ask="subscribe" subscription="none"/></query></iq>
 
 //删除用户
 
 <iq xmlns="jabber:client" type="set" id="965-376" to="user2@chtekimacbook-pro.local/e799ef0c"><query xmlns="jabber:iq:roster"><item jid="user6@chtekimacbook-pro.local" subscription="remove"/></query></iq>
 */

// 添加好友,验证等可在此判断
// 被删除好友

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq{
    
    NSLog(@"didReceiveRosterPush:(XMPPIQ *)iq is :%@",iq.XMLString);
    
    //好友列表
    
    if ([@"set" isEqualToString:iq.type]) {
        
        NSXMLElement *query = iq.childElement;
        
        if ([@"query" isEqualToString:query.name]) {
            
//            NSMutableArray *userArray = [NSMutableArray array];
            
            NSArray *items = [query children];
            
            for (NSXMLElement *item in items) {
                
                NSString *jid = [item attributeStringValueForName:@"jid"];
                NSString *name = [item attributeStringValueForName:@"name"];
                
                NSString *to = iq.toStr;
                NSString *from = iq.fromStr;
                
                NSLog(@"---->jid:%@ name:%@ to:%@ from:%@",jid,name,to,from);
            }
        }
    }

}

/**
 * Sent when the initial roster is received.
 *
 */
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender{
    NSLog(@"xmppRosterDidBeginPopulating");
}

/**
 * Sent when the initial roster has been populated into storage.
 *
 */
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender{
    NSLog(@"xmppRosterDidEndPopulating");
}

/**
 * Sent when the roster recieves a roster item.
 *
 * Example:
 *
 * <item jid='romeo@example.net' name='Romeo' subscription='both'>
 *   <group>Friends</group>
 * </item>
 *
 */

- (void)xmppRoster:(XMPPRoster *)sender didRecieveRosterItem:(NSXMLElement *)item{
    
    NSString *jid = [item attributeStringValueForName:@"jid"];
    NSString *name = [item attributeStringValueForName:@"name"];
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
    
    NSXMLElement *groupElement = [item elementForName:@"group"];
    NSString *group = [groupElement attributeStringValueForName:@"group"];
    
    NSLog(@"didRecieveRosterItem:  jid=%@ ,name=%@ ,subscription=%@,group=%@",jid,name,subscription,group);
    
}

#pragma - mark xmppReconnectDelegate

- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags
{
    NSLog(@"didDetectAccidentalDisconnect %d",connectionFlags);
    
    //更新离线时间
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags
{
    
    NSLog(@"shouldAttemptAutoReconnect %d",reachabilityFlags);
    
    return YES;
}

@end
