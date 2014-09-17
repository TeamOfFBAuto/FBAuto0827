//
//  FBChatViewController.m
//  FBAuto
//
//  Created by lichaowei on 14-7-4.
//  Copyright (c) 2014年 szk. All rights reserved.
//

#import "FBChatViewController.h"
#import "CWInputView.h"
#import "KKMessageCell.h"

#import "NSAttributedString+Attributes.h"
#import "FBHelper.h"
#import "MarkupParser.h"
#import "OHAttributedLabel.h"
#import "SCGIFImageView.h"
#import "XMPPStatics.h"
#import "UIImageView+WebCache.h"
#import "FBAddFriendsController.h"

#import "XMPPServer.h"
#import "SJAvatarBrowser.h"
#import "FBChatImage.h"

#import "ASIFormDataRequest.h"
#import "GDataXMLNode.h"
#import "FBCityData.h"

#import "FBDetail2Controller.h"
#import "FBFindCarDetailController.h"

#import "DXAlertView.h"
#import "GuserZyViewController.h"

#define MESSAGE_PAGE_SIZE 10


@interface FBChatViewController ()<CWInputDelegate,OHAttributedLabelDelegate,chatDelegate,messageDelegate,UIGestureRecognizerDelegate,EGORefreshTableDelegate,UIScrollViewDelegate>
{
    CWInputView *inputBar;
    
    OHAttributedLabel *currentLabel;
    
    NSMutableArray *messages;//文本
    NSMutableArray *rowHeights;//所有高度
    NSDictionary *emojiDic;//所有表情
    NSMutableArray *labelArr;//所有label
    
    XMPPServer *_xmppServer;//xmpp 中心
    
    int currentPage;
    
    BOOL notStart;//刚出现键盘
    
    NSString *userState;//xmpp在线状态
    
    BOOL sendOffline;//是否发送离线消息通知给服务端
    
}

@property (nonatomic,assign)BOOL                        reloading;         //是否正在loading
@property (nonatomic,assign)BOOL                        isLoadMoreData;    //是否是载入更多
@property (nonatomic,assign)BOOL                        isHaveMoreData;    //是否还有更多数据,决定是否有更多view

@property (nonatomic,retain)EGORefreshTableHeaderView * refreshHeaderView;

@end


@implementation FBChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
    [defalts setObject:@"no" forKey:CHATING_USER];
    [defalts synchronize];
    
    [super viewWillDisappear:animated];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.titleLabel.text = (self.chatWithUserName.length > 0) ? self.chatWithUserName : self.chatWithUser;
    
    UIButton *rightButton =[[UIButton alloc]initWithFrame:CGRectMake(0,8,30,21.5)];
    [rightButton addTarget:self action:@selector(clickToHome:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setImage:[UIImage imageNamed:@"shouye48_44"] forState:UIControlStateNormal];
    UIBarButtonItem *save_item=[[UIBarButtonItem alloc]initWithCustomView:rightButton];
    
    UIButton *rightButton2 =[[UIButton alloc]initWithFrame:CGRectMake(0,8,30,21.5)];
    [rightButton2 addTarget:self action:@selector(clickToAdd:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton2 setImage:[UIImage imageNamed:@"tianjia44_44"] forState:UIControlStateNormal];
    UIBarButtonItem *save_item2=[[UIBarButtonItem alloc]initWithCustomView:rightButton2];
    self.navigationItem.rightBarButtonItems = @[save_item,save_item2];
    
    self.table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 320, self.view.height - 44 - 20 - 50) style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_table];
    _table.decelerationRate = 0.8;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickToHideKeyboard)];
    tap.cancelsTouchesInView = NO;
    [_table addGestureRecognizer:tap];
    
    
    XMPPServer *xmppServer = [XMPPServer shareInstance];
    xmppServer.chatDelegate = self;
    xmppServer.messageDelegate = self;
    
    if (![xmppServer.xmppStream isAuthenticated])
    {
        NSLog(@"未认证");
        
        [[XMPPServer shareInstance]loginTimes:10 loginBack:^(BOOL result) {
            if (result) {
                NSLog(@"连接并且登录成功");
            }else{
                NSLog(@"连接登录不成功");
            }
        }];
    }
    
    messages = [NSMutableArray array];
    labelArr = [NSMutableArray array];
    rowHeights = [NSMutableArray array];
    
    [self createInputView];
    
    //获取用户在线状态
    
    [self requestUserState:self.chatWithUser];

    //将当前聊天用户的未读数设为 0
    
    NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defalts objectForKey:XMPP_USERID];
    
    [FBCityData updateCurrentUserPhone:userName fromUserPhone:self.chatWithUser fromName:Nil fromId:nil newestMessage:Nil time:Nil clearReadSum:YES];
    
    NSDictionary *dic = @{@"fromPhone":self.chatWithUser,@"unreadNum":@"0"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fromUnread" object:nil userInfo:dic];
    
    //记录当前聊天人
    
    [defalts setObject:self.chatWithUser forKey:CHATING_USER];
    [defalts synchronize];
    
    if (self.isShare) {
        [self goToShare];
    }
    
    [self getMessageData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    //记录当前聊天人
    
    NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
    [defalts setObject:@"no" forKey:CHATING_USER];
    [defalts synchronize];
    
    _table.delegate = nil;
    _table.dataSource = nil;
    _table = nil;
    _refreshHeaderView = nil;
    
    NSLog(@" %s ",__FUNCTION__);
    
    XMPPServer *xmppServer = [XMPPServer shareInstance];
    xmppServer.chatDelegate = nil;
    xmppServer.messageDelegate = nil;

}

#pragma mark - 数据解析
#pragma mark

- (void)getMessageData
{
    currentPage = 0;
    [self loadarchivemsg:currentPage];
    [self createHeaderView];
}

- (void)freindArray
{
    XMPPServer *xmppServer = [XMPPServer shareInstance];
    
    NSManagedObjectContext *context = [[xmppServer xmppRosterStorage] mainThreadManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    NSError *error ;
    NSArray *friends = [context executeFetchRequest:request error:&error];
    
    for (XMPPUserCoreDataStorageObject *object in friends) {
        
        NSString *name = [object displayName];
        if (!name) {
            name = [object nickname];
        }
        if (!name) {
            name = [object jidStr];
        }
        
        
        NSLog(@"freindArray %@ display %@ nickname %@",name,[object displayName],[object nickname]);
    }
}

#pragma - mark 聊天历史记录

- (void)loadarchivemsg:(int)offset
{
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                         inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    
    [request setFetchLimit:MESSAGE_PAGE_SIZE];
    [request setFetchOffset:offset];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sort]];
    
    NSLog(@"offset %d",offset);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults objectForKey:XMPP_USERID];
    NSString *server = [defaults objectForKey:XMPP_SERVER];
    
    NSString *chatWithJid = [NSString stringWithFormat:@"%@@%@",self.chatWithUser,server];
    NSString *currentJid = [NSString stringWithFormat:@"%@@%@",userName,server];
    
    //bareJidStr 代表与谁聊天
    //body 内容
    //streamBareJidStr 当前用户
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(bareJidStr like[cd] %@ )&& (streamBareJidStr like[cd] %@)",chatWithJid,currentJid];
    
    [request setPredicate:predicate];
    
    [request setEntity:entityDescription];
    NSError *error;
    NSArray *messages_arc = [moc executeFetchRequest:request error:&error];
    
    [self print:[[NSMutableArray alloc]initWithArray:messages_arc]];
}

- (void)print:(NSMutableArray*)messages_arc{
    
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path=[paths objectAtIndex:0];
    NSLog(@"path %@",path);
    
    if (messages_arc.count == 0) {
        
        
        self.isHaveMoreData = NO;
        [self performSelector:@selector(finishReloadigData) withObject:nil afterDelay:0.5];
        
        return;
    }
    
    @autoreleasepool {
        
        for (XMPPMessageArchiving_Message_CoreDataObject *message in messages_arc) {
            
            XMPPMessage *message12=[[XMPPMessage alloc]init];
            message12 = [message message];
            
            NSLog(@" kakakka--->message %@ %@",message.timestamp,message.body);
            
            NSString *msg = [[message12 elementForName:@"body"] stringValue];
            NSString *from = [[message12 attributeForName:@"from"] stringValue];
            
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *time = [format stringFromDate:message.timestamp];
            
            
            if(msg)
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                [dict setObject:msg forKey:@"msg"];
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *userName = [defaults objectForKey:XMPP_USERID];
                
                if ([from hasPrefix:userName]) {
                    from = @"you";
                }
                [dict setObject:from forKey:@"sender"];
                
                //分享信息id
                NSString *infoId = [[message12 attributeForName:MESSAGE_SHATE_LINK] stringValue];
                NSString *shareType = [[message12 attributeForName:SHARE_TYPE_KEY] stringValue];
                if (infoId) {
                    [dict setObject:infoId forKey:MESSAGE_SHATE_LINK];
                    NSLog(@"info ---> %@",infoId);
                }
                if (shareType) {
                    [dict setObject:shareType forKey:SHARE_TYPE_KEY];
                }
                
                //消息接收到的时间
                [dict setObject:(time ? time : @"") forKey:@"time"];
                
                [messages insertObject:dict atIndex:0];
                
                NSLog(@"messages %@",messages);
                
                [self createRichLabelWithMessage:dict isInsert:YES];
                
            }
        }
        
        self.isHaveMoreData = YES;
        [self performSelector:@selector(finishReloadigData) withObject:nil afterDelay:0.5];
        
        if (_reloading) {
            return;
        }
        
        [self scrollToBottom];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[FBChatImage class]]) {
        
        return NO;
    }
    
    return YES;
}

/**
 *  内容滑动到最后一条
 */
- (void)scrollToBottom
{
    if (messages.count > 1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count - 1 inSection:0];;
        [self.table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    }
}

/**
 *   缩放图片
 */

-(UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width*scaleSize,image.size.height*scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height *scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}


#pragma mark - 网络请求
#pragma mark

/**
 *  获取用户在线状态
 *
 */

- (NSString *)requestUserState:(NSString *)userId
{
    //http://60.18.147.4:9090/plugins/presence/status?jid=18612389982@60.18.147.4&type=xml
    
    NSString *server = [[NSUserDefaults standardUserDefaults]objectForKey:XMPP_SERVER];
    
    NSString *url = [NSString stringWithFormat:@"http://%@:9090/plugins/presence/status?jid=%@@%@&type=xml",server,userId,server];
    NSString *newUrl = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *urlS = [NSURL URLWithString:newUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlS cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:2];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (data.length > 0) {
            
            NSError *erro;
            GDataXMLDocument *document = [[GDataXMLDocument alloc]initWithData:data error:&erro];
            GDataXMLElement *rootElement = [document rootElement];
            
            NSString *rootString = [NSString stringWithFormat:@"%@",rootElement];
            NSString *str = [rootElement stringValue];
            
            if ([rootString rangeOfString:@"erro"].length > 0) {
                
                NSLog(@"说明有错误");
                
                userState = @"unavailable";
                
                sendOffline = YES;
                
            }else if (str && [str isEqualToString:@"Unavailable"]) {
                
                //离线状态
                
                NSLog(@"离线");
                
                userState = @"unavailable";
                sendOffline = YES;
                
            }else
            {
                NSLog(@"在线");
                
                userState = @"vailable";
                
                sendOffline = NO;
            }
            
            
            //{type:1 name:presence xml:"<presence type="unavailable" from="13301072337@60.18.147.4"><status>Unavailable</status></presence>
            
            //{type:1 name:presence xml:"<presence from="13301072337@60.18.147.4/714c0af9" to="13301072337@60.18.147.4/714c0af9"/>"}
            
            NSLog(@"erro %@ rootElement %@ str %@",erro,rootElement,str);
            
        }
    }];
    
    return @"no";
}

/**
 *  发送离线消息时通知服务端
 */
- (void)sendOffline
{
    NSString *url = [NSString stringWithFormat:FBAUTO_CHAT_OFFLINE,self.chatUserId,@"1",[GMAPI getUid],[GMAPI getUserPhoneNumber]];
    LCWTools *tool = [[LCWTools alloc]initWithUrl:url isPost:NO postData:nil];
    [tool requestCompletion:^(NSDictionary *result, NSError *erro) {
        
        NSLog(@"result %@ erro %@",result,erro);
        
    } failBlock:^(NSDictionary *failDic, NSError *erro) {
        
        NSLog(@"failDic %@ erro %@",failDic,erro);
        
    }];
}

/**
 *  XMPP发送消息
 */

- (void)xmppSendMessage:(NSString *)messageText
{
    
    if (sendOffline) {
        
        [self sendOffline];
        
        NSLog(@"需要 sendOffline");
        
    }else
    {
        NSLog(@"不需要 sendOffline");
    }
    
    
    __weak typeof(self)weakSelf = self;
    
    NSString *shareType = [self.shareContent objectForKey:SHARE_TYPE_KEY];
    NSString *shareInfoId = [self.shareContent objectForKey:@"infoId"];
    
    NSDictionary *shareLink;
    if (shareType && shareInfoId) {
        
        shareLink = @{SHARE_TYPE_KEY: shareType,MESSAGE_SHATE_LINK:shareInfoId};
    }
    
    XMPPServer *xmppServer = [XMPPServer shareInstance];
    
    [xmppServer sendMessage:messageText toUser:self.chatWithUser shareLink:shareLink messageBlock:^(NSDictionary *params, int tag) {
        
        if (tag == 1) {
            
            NSLog(@"发送成功 didSendMessage");
            
            //本地记录最新一条聊天消息
            
            [FBCityData updateCurrentUserPhone:[GMAPI getUserPhoneNumber] fromUserPhone:self.chatWithUser fromName:self.chatWithUserName fromId:self.chatUserId newestMessage:messageText time:[LCWTools currentTime] clearReadSum:YES];
            
            if (weakSelf.isShare) {
                
                DXAlertView *alert = [[DXAlertView alloc]initWithTitle:@"分享成功" contentText:nil leftButtonTitle:@"返回" rightButtonTitle:@"留在此页" isInput:NO];
                [alert show];
                
                alert.leftBlock = ^(){
                    NSLog(@"返回");
                    
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                };
                alert.rightBlock = ^(){
                    NSLog(@"确定");
                    
                };
            }
            
        }else{
            
            NSLog(@"发送失败 didFailToSendMessage");
        }
        
    }];
}

#pragma - mark 图片上传

- (void)postImages:(UIImage *)eImage
{
    
    if (eImage == nil) {
        return;
    }
    
    FBChatImage *chatImage = nil;
    
    id aView = [labelArr lastObject];
    
    if ([aView isKindOfClass:[FBChatImage class]]) {
        
        chatImage = aView;
    }
    
    [chatImage startLoading];//开始菊花
    
    NSString* url = [NSString stringWithFormat:FBAUTO_CHAT_TALK_PIC];
    
    ASIFormDataRequest *uploadImageRequest= [ ASIFormDataRequest requestWithURL : [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ]];
    [uploadImageRequest setStringEncoding:NSUTF8StringEncoding];
    [uploadImageRequest setRequestMethod:@"POST"];
    [uploadImageRequest setResponseEncoding:NSUTF8StringEncoding];
    [uploadImageRequest setPostValue:[GMAPI getAuthkey] forKey:@"authkey"];//参数一 authkey
    [uploadImageRequest setPostFormat:ASIMultipartFormDataPostFormat];
    [uploadImageRequest setTimeOutSeconds:30];
    
    UIImage *new = [SzkAPI scaleToSizeWithImage:eImage size:CGSizeMake(eImage.size.width>1024?1024:eImage.size.width,eImage.size.width>1024?eImage.size.height*1024/eImage.size.width:eImage.size.height)];
    
    NSData *imageData=UIImageJPEGRepresentation(new, 0.5);
    
    UIImage * newImage = [UIImage imageWithData:imageData];
    
    NSString *photoName=[NSString stringWithFormat:@"FBAuto_xmpp.png"];
    NSLog(@"photoName:%@",photoName);
    NSLog(@"图片大小:%f",(float)[imageData length]/1024/1024);
    
    [uploadImageRequest addData:imageData withFileName:photoName andContentType:@"image/png" forKey:@"talkpic"];
    
    [uploadImageRequest setDelegate : self ];
    
    [uploadImageRequest startAsynchronous];
    
    __weak typeof(ASIFormDataRequest *)weakRequst = uploadImageRequest;
    
    __weak typeof (FBChatImage *)weakChatV = chatImage;
    
    __weak typeof(self)weakSelf = self;
    //完成
    [uploadImageRequest setCompletionBlock:^{
        
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:weakRequst.responseData options:0 error:nil];
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            
            int erroCode = [[result objectForKey:@"errcode"]intValue];
            NSString *erroInfo = [result objectForKey:@"errinfo"];
            
            if (erroCode != 0) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:erroInfo delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
                
                return ;
            }
            
            NSArray *dataInfo = [result objectForKey:@"datainfo"];
            NSMutableArray *imageIdArr = [NSMutableArray arrayWithCapacity:dataInfo.count];
            
            NSString *imageLink = @"";
            
            for (NSDictionary *imageDic in dataInfo) {
                NSString *imageId = [imageDic objectForKey:@"imageid"];
                imageLink = [imageDic objectForKey:@"image"];
                [imageIdArr addObject:imageId];
            }
            
            [weakChatV showBigImage:^(UIImageView *imageView) {
                
                NSMutableString *str = [NSMutableString stringWithString:imageLink];
                [str replaceOccurrencesOfString:@"small" withString:@"ori" options:0 range:NSMakeRange(0, str.length)];
                [SJAvatarBrowser showImage:imageView imageUrl:str];
                
            }];
            
            [weakChatV stopLoadingWithFailBlock:nil];//停止菊花
            [weakChatV sd_setImageWithURL:[NSURL URLWithString:imageLink] placeholderImage:[UIImage imageNamed:@"detail_test.jpg"]];
            
            
            CGFloat imageWidth = newImage.size.width;
            CGFloat imageHeight = newImage.size.height;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                
                NSString *sendImage = [NSString stringWithFormat:@"<img height=\"%f\" width=\"%f\" src=\"%@\"/>>",imageHeight,imageWidth,imageLink];
                NSLog(@"sendImage %@",sendImage);
                
                [weakSelf xmppSendMessage:sendImage];
                
            });
        }
        
        
    }];
    
    //失败
    [uploadImageRequest setFailedBlock:^{
        
        NSLog(@"uploadFail %@ erro %@",weakRequst.responseString,weakRequst.responseStatusMessage);
        
        [weakChatV stopLoadingWithFailBlock:^(FBChatImage *chatImageView) {
            
            [weakSelf postImages:eImage];
            
        }];//停止菊花
    }];
    
}

/**
 *  添加好友
 *
 *  @param friendId userId
 */
- (void)addFriend:(NSString *)friendId
{
    NSLog(@"provinceId %@",friendId);
    
    LCWTools *tools = [[LCWTools alloc]initWithUrl:[NSString stringWithFormat:FBAUTO_FRIEND_ADD,[GMAPI getAuthkey],friendId]isPost:NO postData:nil];
    
    [tools requestCompletion:^(NSDictionary *result, NSError *erro) {
        NSLog(@"result %@ erro %@",result,[result objectForKey:@"errinfo"]);
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            
            //            int erroCode = [[result objectForKey:@"errcode"]intValue];
            NSString *erroInfo = [result objectForKey:@"errinfo"];
            
            DXAlertView *alert = [[DXAlertView alloc]initWithTitle:erroInfo contentText:nil leftButtonTitle:nil rightButtonTitle:@"确定" isInput:NO];
            [alert show];
            
            alert.leftBlock = ^(){
                NSLog(@"确定");
            };
            alert.rightBlock = ^(){
                NSLog(@"取消");
                
            };
            
        }
    }failBlock:^(NSDictionary *failDic, NSError *erro) {
        NSLog(@"failDic %@",failDic);
        [LCWTools showDXAlertViewWithText:[failDic objectForKey:ERROR_INFO]];
    }];
}


#pragma mark - 视图创建
#pragma mark

#pragma - mark 创建 richLabel 和 imageView


/**
 *  根据发送的内容返回一个富文本label,并将label加入到label数组中
 *
 *  @param dic 消息字典
 *
 *  @return label
 */
- (CGFloat)createRichLabelWithMessage:(NSDictionary *)dic isInsert:(BOOL)isInsert
{
    //    MESSAGE_TYPE type = [[dic objectForKey:@"type"]integerValue];
    
    //本地发送 图片
    
    BOOL isLocal = [[dic objectForKey:MESSAGE_MESSAGE_LOCAL]boolValue];
    if (isLocal) { //图片
        
        UIImage *aImage = [dic objectForKey:MESSAGE_MSG];
        FBChatImage *aImageView = [[FBChatImage alloc]init];
        aImageView.image = aImage;
        aImageView.userInteractionEnabled = YES;
        
        
        if (isInsert) {
            [labelArr insertObject:aImageView atIndex:0];
        }else
        {
            [labelArr addObject:aImageView];
        }
        
        [aImageView showBigImage:^(UIImageView *imageView) {
            
            [SJAvatarBrowser showImage:imageView imageUrl:nil];
            
        }];
        
        //最多高度 200,最大宽度 200
        [XMPPStatics updateFrameForImageView:aImageView originalWidth:aImage.size.width originalHeight:aImage.size.height];
        
        NSNumber *heightNum = [[NSNumber alloc] initWithFloat:aImageView.height];
        
        if (isInsert) {
            [rowHeights insertObject:heightNum atIndex:0];
        }else
        {
            [rowHeights addObject:heightNum];
            
        }
        
        
        return [heightNum floatValue];
    }
    
    //网络获取 图片
    
    NSString *msg = [dic objectForKey:MESSAGE_MSG];
    
    NSString *url = [XMPPStatics imageUrl:msg] ;
    if (![url isEqualToString:@""]) {
        //是图片
        CGFloat width = [XMPPStatics imageValue:msg for:@"width"];
        CGFloat height = [XMPPStatics imageValue:msg for:@"height"];
        
        
        FBChatImage *aImageView = [[FBChatImage alloc]initWithFrame:CGRectMake(0, 0, width, height)];
        
        
        if (isInsert) {
            [labelArr insertObject:aImageView atIndex:0];
        }else
        {
            [labelArr addObject:aImageView];
            
        }
        
        [aImageView showBigImage:^(UIImageView *imageView) {
            
            
            NSMutableString *str = [NSMutableString stringWithString:url];
            [str replaceOccurrencesOfString:@"small" withString:@"ori" options:0 range:NSMakeRange(0, str.length)];
            [SJAvatarBrowser showImage:imageView imageUrl:str];
            
        }];
        
        __weak typeof (FBChatImage *)weakChatV = aImageView;
        
        [aImageView startLoading];
        
        [aImageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"detail_test.jpg"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [weakChatV stopLoadingWithFailBlock:nil];
            
        }];
        
        //最多高度 200,最大宽度 200
        [XMPPStatics updateFrameForImageView:aImageView originalWidth:width originalHeight:height];
        
        NSNumber *heightNum = [[NSNumber alloc] initWithFloat:aImageView.height];
        
        if (isInsert) {
            [rowHeights insertObject:heightNum atIndex:0];
        }else
        {
            [rowHeights addObject:heightNum];
            
        }
        
        return [heightNum floatValue];
    }
    
    OHAttributedLabel *label = [[OHAttributedLabel alloc] initWithFrame:CGRectZero];
    NSString *text = [dic objectForKey:MESSAGE_MSG];
    [self creatAttributedLabel:text Label:label];
    
    NSString *infoId = [dic objectForKey:MESSAGE_SHATE_LINK];
    
    if (infoId && infoId.length > 0) {
        [label addCustomLink:[NSURL URLWithString:text] inRange:NSMakeRange(0,text.length)];
        label.params = dic;
    }
    
    NSNumber *heightNum = [[NSNumber alloc] initWithFloat:label.frame.size.height];
    
    if (isInsert) {
        [labelArr insertObject:label atIndex:0];
    }else
    {
        [labelArr addObject:label];
    }
    
    [self drawImage:label];
    //    [rowHeights addObject:heightNum];
    
    if (isInsert) {
        [rowHeights insertObject:heightNum atIndex:0];
    }else
    {
        [rowHeights addObject:heightNum];
        
    }
    
    return [heightNum floatValue];
}


- (void)creatAttributedLabel:(NSString *)o_text Label:(OHAttributedLabel *)label
{
    [label setNeedsDisplay];
    NSMutableArray *httpArr = [FBHelper addHttpArr:o_text];
    NSMutableArray *phoneNumArr = [FBHelper addPhoneNumArr:o_text];
    
    NSString *text = [FBHelper transformString:o_text];
    text = [NSString stringWithFormat:@"<font color='black' strokeColor='gray' face='Palatino-Roman'>%@",text];
    
    MarkupParser* p = [[MarkupParser alloc] init];
    NSMutableAttributedString* attString = [p attrStringFromMarkup: text];
    [attString setFont:[UIFont systemFontOfSize:16]];
    label.backgroundColor = [UIColor clearColor];
    [label setAttString:attString withImages:p.images];
    
    NSString *string = attString.string;
    
    if ([phoneNumArr count]) {
        for (NSString *phoneNum in phoneNumArr) {
            [label addCustomLink:[NSURL URLWithString:phoneNum] inRange:[string rangeOfString:phoneNum]];
        }
    }
    
    if ([httpArr count]) {
        for (NSString *httpStr in httpArr) {
            [label addCustomLink:[NSURL URLWithString:httpStr] inRange:[string rangeOfString:httpStr]];
        }
    }
    
    label.delegate = self;
    CGRect labelRect = label.frame;
    labelRect.size.width = [label sizeThatFits:CGSizeMake(200, CGFLOAT_MAX)].width;
    labelRect.size.height = [label sizeThatFits:CGSizeMake(200, CGFLOAT_MAX)].height;
    label.frame = labelRect;
    label.onlyCatchTouchesOnLinks = NO;
    label.underlineLinks = YES;//链接是否带下划线
    [label.layer display];
    // 调用这个方法立即触发label的|drawTextInRect:|方法，
    // |setNeedsDisplay|方法有滞后，因为这个需要画面稳定后才调用|drawTextInRect:|方法
    // 这里我们创建的时候就需要调用|drawTextInRect:|方法，所以用|display|方法，这个我找了很久才发现的
}

- (void)drawImage:(OHAttributedLabel *)label
{
    for (NSArray *info in label.imageInfoArr) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:[info objectAtIndex:0] ofType:nil];
        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        SCGIFImageView *imageView = [[SCGIFImageView alloc] initWithGIFData:data];
        imageView.frame = CGRectFromString([info objectAtIndex:2]);
        [label addSubview:imageView];//label内添加图片层
        [label bringSubviewToFront:imageView];
    }
}


#pragma - mark 创建输入框

- (void)createInputView
{
    //键盘
    inputBar = [[CWInputView alloc]initWithFrame:CGRectMake(0, self.view.height - 50 - 20 - 44, 320, 50)];
    inputBar.delegate = self;
    inputBar.clearInputWhenSend = YES;
    inputBar.resignFirstResponderWhenSend = NO;
    
    
    __weak typeof(self)weakSelf = self;
    [inputBar setToolBlock:^(int aTag) {
        
        switch (aTag) {
            case 0:
            {
                NSLog(@"打电话");
                
                NSString *num = [[NSString alloc] initWithFormat:@"tel://%@",weakSelf.chatWithUser];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:num]];
                
            }
                break;
            case 1:
            {
                NSLog(@"拍照");
                [weakSelf clickToCamera:nil];
            }
                break;
            case 2:
            {
                NSLog(@"相册");
                [weakSelf clickToAlbum:nil];
                
            }
                break;
                
            default:
                break;
        }
        
    }];
    
    [inputBar setFrameBlock:^(CWInputView *inputView, CGRect frame, BOOL isEnd) {
        
        [weakSelf resetTableFrameIsNormal:isEnd];
    }];
    
    [self.view addSubview:inputBar];
    
    NSLog(@"-->%f",self.view.height);
}

- (void)resetTableFrameIsNormal:(BOOL)isNormal
{
    
    CGRect aFrame = _table.frame;
    CGFloat aFrameY = 0.0;
    
    if (isNormal) {
        
        aFrameY = 0.0;
        notStart = NO;
        
    }else
    {
        
        CGSize contentSize = self.table.contentSize;
        
//        CGFloat visibleHeight = inputBar.top - 20 - 44;//聊天可视高度
        
        if (contentSize.height > self.table.height) {
            
            aFrameY = inputBar.top - (self.view.height - 50 - 20 - 44) - inputBar.height - 10;
        }
    }
    
    aFrame.origin.y = aFrameY;
    
    __weak typeof(UITableView *)weakTable = _table;
    
    if (notStart == NO) {
        
        [self scrollToBottom];
        
        [UIView animateWithDuration:0.5 animations:^{
            
            weakTable.frame = aFrame;
            
        }];
    }else
    {
        weakTable.frame = aFrame;
    }
    
    notStart = YES;
}



#pragma mark - 事件处理
#pragma mark

/**
 *  验证是否登录成功,否则自动登录再发送
 *  @param aImage 发送图片时aImage不为空
 */

- (void)xmppAuthenticatedWithMessage:(NSString *)text MessageType:(MESSAGE_TYPE)type image:(UIImage *)aImage
{
    
    [self localSendMessage:text MessageType:type image:aImage];
    
    XMPPServer *xmppServer = [XMPPServer shareInstance];
    
    if (![xmppServer.xmppStream isAuthenticated])
    {
        [xmppServer loginTimes:10 loginBack:^(BOOL result) {
            
            if (result) {
                
                NSLog(@"连接 %d",result);
                
                if (aImage) { //说明发送的是图片
                    
                    //需要先上传图片,再发送消息
                    
                    [self postImages:aImage];
                    
                }else
                {
                    [self xmppSendMessage:text];
                    
                }
            }
            
        }];
    }else
    {
        if (aImage) { //说明发送的是图片
            
            //需要先上传图片,再发送消息
            
            [self postImages:aImage];
            
        }else
        {
            [self xmppSendMessage:text];
            
        }
    }
    
}
#pragma - mark 本地发送信息处理

//发送图片的时候,aImage不能为空

- (void)localSendMessage:(NSString *)message MessageType:(MESSAGE_TYPE)type image:(UIImage *)aImage
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (message) {
        [dictionary setObject:message forKey:@"msg"];
    }
    
    [dictionary setObject:@"you" forKey:@"sender"];
    //加入发送时间
    [dictionary setObject:[XMPPStatics getCurrentTime] forKey:@"time"];
    [dictionary setObject:[NSString stringWithFormat:@"%d",type] forKey:@"type"];
    
    if (aImage) {
        
        [dictionary setObject:aImage forKey:MESSAGE_MSG];
        [dictionary setObject:[NSNumber numberWithBool:YES] forKey:MESSAGE_MESSAGE_LOCAL];
    }
    
    if (self.shareContent) {
        
        NSString *shareId = [self.shareContent objectForKey:@"infoId"];
        NSString *shareType = [self.shareContent objectForKey:SHARE_TYPE_KEY];
        
        [dictionary setObject:shareId ? shareId : @"" forKey:MESSAGE_SHATE_LINK];
        [dictionary setObject:shareType ? shareType : @"" forKey:SHARE_TYPE_KEY];
    }
    
    //分享链接
    
    
    [messages addObject:dictionary];
    
    //重新刷新tableView
    [self.table reloadData];
    
    if (_reloading) {
        
        return;
    }
    [self scrollToBottom];
}

#pragma - mark 点击发送消息 CWInputDelegate

- (void)inputView:(CWInputView *)inputView sendBtn:(UIButton*)sendBtn inputText:(NSString*)text
{
    NSLog(@"text %@",text);
    
    if (![text isEqualToString:@""] && text.length > 0) {
        
        NSLog(@"直接发送");
        
        [self xmppAuthenticatedWithMessage:text MessageType:Message_Normal image:nil];
    }
}

#pragma - mark 分享操作

- (void)goToShare
{
    DXAlertView *alert = [[DXAlertView alloc]initWithTitle:nil contentText:[self.shareContent objectForKey:@"text"] leftButtonTitle:@"取消" rightButtonTitle:@"分享" isInput:YES];
    [alert show];
    
    __weak typeof(self)weakSelf=self;
    __weak typeof(DXAlertView *)weakAlert = alert;
    alert.leftBlock = ^(){
        NSLog(@"取消");
        
        [self.navigationController popViewControllerAnimated:YES];
    };
    alert.rightBlock = ^(){
        NSLog(@"确定");
        
        [weakSelf xmppAuthenticatedWithMessage:weakAlert.inputTextView.text MessageType:Message_Normal image:nil];
     };

}


#pragma - mark  click事件

- (void)clickToHideKeyboard
{
    [inputBar resignFirstResponder];
}

- (void)clickToAdd:(UIButton *)btn
{
    
    [self addFriend:self.chatUserId];

}

- (void)clickToHome:(UIButton *)btn
{
//    [self.navigationController popToRootViewControllerAnimated:YES];
    
    GuserZyViewController *personal = [[GuserZyViewController alloc]init];
    personal.title = self.chatWithUserName ? self.chatWithUserName : self.chatUserId;
    personal.userId = self.chatUserId;
    [self.navigationController pushViewController:personal animated:YES];
}

#pragma - mark 发送图片

//打开相册

- (IBAction)clickToAlbum:(id)sender {
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        
        BOOL is =  [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
        if (is) {
            UIImagePickerController *picker = [[UIImagePickerController alloc]init];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:picker animated:YES completion:^{
            }];
        }else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"不支持相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"不支持iPad相册选取图片" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

//打开相机

- (IBAction)clickToCamera:(id)sender {
    
    BOOL is =  [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    if (is) {
        UIImagePickerController *picker = [[UIImagePickerController alloc]init];
        picker.delegate = self;
        
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:^{
            
        }];
    }else
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"不支持相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma  mark  - delegate
#pragma  mark

#pragma - mark imagePicker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.image"]) {
        
        //压缩图片 不展示原图
        UIImage *originImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        //先上传图片
        
        [self localSendMessage:Nil MessageType:Message_Image image:originImage];
        
        //再实际发送
        
        [self postImages:originImage];
        
        [picker dismissViewControllerAnimated:NO completion:^{
            
            
        }];
        
    }
}

#pragma - mark QBImagePicker delegate

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)aImagePickerController
{
    [aImagePickerController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


#pragma - mark OHAttributedLabelDelegate

-(BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel shouldFollowLink:(NSTextCheckingResult*)linkInfo
{
    NSString *requestString = [linkInfo.URL absoluteString];
    NSLog(@"%@",requestString);
    
    NSString *info = [attributedLabel.params objectForKey:MESSAGE_SHATE_LINK];
    
    NSString *shareType = [attributedLabel.params objectForKey:SHARE_TYPE_KEY];
    
    NSArray *params = [info componentsSeparatedByString:@","];
    if (params.count > 1) {
        
        NSString *infoId = [params objectAtIndex:0];
        NSString *carId = [params objectAtIndex:1];
        
        
        if([shareType isEqualToString:SHARE_CARSOURCE])
        {
            NSLog(@"车源");
            FBDetail2Controller *detail = [[FBDetail2Controller alloc]init];
            detail.style = Navigation_Special;
            detail.navigationTitle = @"详情";
            detail.infoId = infoId;
            detail.carId = carId;
            detail.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:detail animated:YES];
            
        }else
        {
            NSLog(@"寻车");
            FBFindCarDetailController *detail = [[FBFindCarDetailController alloc]init];
            detail.style = Navigation_Special;
            detail.navigationTitle = @"详情";
            detail.infoId = info;
            detail.carId = carId;
            detail.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:detail animated:YES];
        }
    }
    
    if ([[UIApplication sharedApplication]canOpenURL:linkInfo.URL]) {
        [[UIApplication sharedApplication]openURL:linkInfo.URL];
    }
    return NO;
}


#pragma - mark messageDelegate 消息代理 <NSObject>

- (void)newMessage:(NSDictionary *)messageDic
{
    NSLog(@"newMessage %@",messageDic);
    
    NSString *sender = [messageDic objectForKey:@"sender"];
    
    NSLog(@"sender %@ chatWith %@",sender,self.chatWithUser);
    
    //是当前聊天用户才刷新页面
    
    if (sender && [sender hasPrefix:(self.chatWithUser ? self.chatWithUser : @"")]) {
        [messages addObject:messageDic];
        [self.table reloadData];
        
        [self scrollToBottom];
    }
}


#pragma - mark XMPP 用户状态代理 chatDelegate

-(void)userOnline:(User *)user
{
    NSLog(@"userOnline:%@  type:%@",user.userName,user.presentType);
    
//    NSString *str = [NSString stringWithFormat:@"%@ 上线",user.userName];
//    
//    [LCWTools showDXAlertViewWithText:str];
    
    if ([self.chatWithUser isEqualToString:user.userName]) {
        //聊天对象离线
        userState = @"available";
        
        sendOffline = NO;
        
    }
    
    
}
-(void)userOffline:(User *)user
{
    NSLog(@"userOffline %@ %@",user.userName,user.presentType);
    
//    NSString *str = [NSString stringWithFormat:@"%@ 下线",user.userName];
//    
//    [LCWTools showDXAlertViewWithText:str];
    
    if ([self.chatWithUser isEqualToString:user.userName]) {
        //聊天对象离线
        userState = @"unavailable";
        
        sendOffline = YES;
    }
    
}

- (void)friendsArray:(NSArray *)array //好友列表
{
    NSLog(@"friendsArray:%@",array);
}

//改变上线状态

- (void)changeOnlineState:(User *)user
{
    NSLog(@"user:%@ changeOnlineState",user);
}

//用户是否已在列表

- (BOOL)isUserAdded:(User *)user
{
    //    for (User *aUser in onlineUsers) {
    //        if ([user.userName isEqualToString:aUser.userName]) {
    //            return YES;
    //        }
    //    }
    return NO;
}


#pragma - mark UITableView 代理

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [messages count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"msgCell";
    
    KKMessageCell *cell =(KKMessageCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[KKMessageCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSMutableDictionary *dict = [messages objectAtIndex:indexPath.row];
    if (labelArr.count > indexPath.row && [labelArr objectAtIndex:indexPath.row]) {
        
    }else
    {
        //否则没有,需要新创建
        [self createRichLabelWithMessage:dict isInsert:NO];
        
    }
    
    UIView *label = (UIView *)[labelArr objectAtIndex:indexPath.row];
    
    CGFloat labelHeight = [[rowHeights objectAtIndex:indexPath.row] floatValue];
    [cell loadDataWithDic:dict labelHeight:labelHeight OHLabel:label];
    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath NS_AVAILABLE_IOS(6_0)
{
    KKMessageCell *aCell =(KKMessageCell *)cell;
    if (aCell.OHLabel) {
        [aCell.OHLabel removeFromSuperview];//防止重绘
    }
}

//每一行的高度
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSMutableDictionary *dict = [messages objectAtIndex:indexPath.row];
    if (rowHeights.count > indexPath.row && [rowHeights objectAtIndex:indexPath.row]) {
        
    }else
    {
        [self createRichLabelWithMessage:dict isInsert:NO];
    }
    
    CGFloat labelHeight = [[rowHeights objectAtIndex:indexPath.row] floatValue] + 20 + 20 + 20;
    
    return labelHeight;
    
}

#pragma - mark UIScrollView 代理 (控制gif动画)

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    NSNotification *notification = [NSNotification notificationWithName:@"ChangeStart" object:[NSNumber numberWithBool:NO]];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSNotification *notification = [NSNotification notificationWithName:@"ChangeStart" object:[NSNumber numberWithBool:YES]];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}


#pragma mark -  下拉加载更多
#pragma mark


#pragma - mark EGORefresh

-(void)createHeaderView
{
    if (_refreshHeaderView && _refreshHeaderView.superview) {
        [_refreshHeaderView removeFromSuperview];
    }
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc]initWithFrame:CGRectMake(0.0f,0.0f -self.view.frame.size.height, self.view.frame.size.width, self.view.bounds.size.height)];
    _refreshHeaderView.delegate = self;
    _refreshHeaderView.backgroundColor = [UIColor clearColor];
    [self.table addSubview:_refreshHeaderView];
    [_refreshHeaderView refreshLastUpdatedDate];
}
-(void)removeHeaderView
{
    if (_refreshHeaderView && [_refreshHeaderView superview]) {
        [_refreshHeaderView removeFromSuperview];
    }
    _refreshHeaderView = Nil;
}

#pragma mark-
#pragma mark force to show the refresh headerView
//代码触发刷新
-(void)showRefreshHeader:(BOOL)animated
{
    if (animated)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        self.table.contentInset = UIEdgeInsetsMake(65.0f, 0.0f, 0.0f, 0.0f);
        [self.table scrollRectToVisible:CGRectMake(0, 0.0f, 1, 1) animated:NO];
        [UIView commitAnimations];
    }
    else
    {
        self.table.contentInset = UIEdgeInsetsMake(65.0f, 0.0f, 0.0f, 0.0f);
        [self.table scrollRectToVisible:CGRectMake(0, 0.0f, 1, 1) animated:NO];
    }
    
    [_refreshHeaderView setState:EGOOPullRefreshLoading];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.table];
}

#pragma mark - EGORefreshTableDelegate
- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos
{
    [self beginToReloadData:aRefreshPos];
}

//根据刷新类型，是看是下拉还是上拉
-(void)beginToReloadData:(EGORefreshPos)aRefreshPos
{
    self.reloading = YES;
    
    if (aRefreshPos == EGORefreshHeader)
    {
        self.isLoadMoreData = YES;
        
        currentPage += MESSAGE_PAGE_SIZE;
        [self loadarchivemsg:currentPage];
        
    }
}

//完成数据加载
- (void)finishReloadigData
{
    NSLog(@"finishReloadigData完成加载");
    
    _reloading = NO;
    
    if (_refreshHeaderView)
    {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.table];
        self.isLoadMoreData = NO;
    }

    [self.table reloadData];
    
    //如果有更多数据，重新设置footerview  frame
    
    
    if (self.isHaveMoreData)
    {
        [self createHeaderView];
        
    }else
    {
        [self removeHeaderView];
        
        NSLog(@"----");
    }
}

- (BOOL)egoRefreshTableDataSourceIsLoading:(UIView*)view
{
    return _reloading;
}
- (NSDate*)egoRefreshTableDataSourceLastUpdated:(UIView*)view
{
    return [NSDate date];
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_refreshHeaderView) {
        [_refreshHeaderView egoRefreshScrollViewDidScroll:self.table];
    }
    
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
    if (_refreshHeaderView)
    {
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.table];
        
    }
}

@end
