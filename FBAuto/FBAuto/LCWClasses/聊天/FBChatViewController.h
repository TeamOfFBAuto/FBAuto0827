//
//  FBChatViewController.h
//  FBAuto
//
//  Created by lichaowei on 14-7-4.
//  Copyright (c) 2014年 FBLife. All rights reserved.
//

#import "FBBaseViewController.h"

typedef enum{
    Message_Normal = 0,//普通文本、表情
    Message_Image,//图片
}MESSAGE_TYPE;

/**
 *  聊天、好友信息页
 */
@interface FBChatViewController : FBBaseViewController<UITableViewDataSource,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,NSXMLParserDelegate>

@property(nonatomic,retain)UITableView *table;

@property(nonatomic,retain)NSString *chatWithUser;//交流用户(phone)
@property(nonatomic,retain)NSString *chatWithUserName;//交流用户Name
@property(nonatomic,retain)NSString *chatUserId;//交流用户(userId)

@property(nonatomic,assign)BOOL isShare;//是否来自分享
@property(nonatomic,retain)NSDictionary *shareContent;//分享的内容  {@"text",@"infoId"}

@end
