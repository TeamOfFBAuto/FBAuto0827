//
//  KKMessageCell.m
//  XmppDemo
//

#import "KKMessageCell.h"

#define KLEFT 10
#define KDIS 10

@implementation KKMessageCell

@synthesize senderAndTimeLabel;
@synthesize messageContentView;
@synthesize bgImageView;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //日期标签
        senderAndTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 300, 20)];
        //居中显示
        senderAndTimeLabel.textAlignment = NSTextAlignmentCenter;
        senderAndTimeLabel.font = [UIFont systemFontOfSize:11.0];
        //文字颜色
        senderAndTimeLabel.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:senderAndTimeLabel];
        
        //背景图
        bgImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        bgImageView.backgroundColor = [UIColor clearColor];
        bgImageView.userInteractionEnabled = YES;
        [self.contentView addSubview:bgImageView];
        
        //聊天信息
        messageContentView = [[UITextView alloc] init];
        messageContentView.backgroundColor = [UIColor clearColor];
        //不可编辑
        messageContentView.editable = NO;
        messageContentView.scrollEnabled = NO;
        [messageContentView sizeToFit];
        [self.contentView addSubview:messageContentView];

    }
    
    return self;
    
}

- (void)refreshCell
{
    [self.OHLabel removeFromSuperview];
}

- (void)loadDataWithDic:(NSDictionary *)dict labelHeight:(CGFloat)labelHeight OHLabel:(UIView *)OHLabel
{
    self.OHLabel = OHLabel;
    //发送者
    NSString *sender = [dict objectForKey:MESSAGE_SENDER];
    //消息
//    NSString *message = [dict objectForKey:MESSAGE_MSG];
    //时间
    NSString *time = [dict objectForKey:MESSAGE_TIME];
    
//    self.senderAndTimeLabel.text = [NSString stringWithFormat:@"%@ %@", sender, time];
    
//    NSDateFormatter *date = [[NSDateFormatter alloc] init];
//    [date setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSDate *compareDate = [date dateFromString:time];
//    
//    time = [NSString stringWithFormat:@"%@",compareDate];
    
    
    self.senderAndTimeLabel.text = [NSString stringWithFormat:@"%@",time];
    
    [self.bgImageView addSubview:OHLabel];
    
    CGSize aSize = OHLabel.bounds.size;
    
    CGFloat left = 0.0f;
    
    CGFloat dix = 0.0f;//左右偏移
    
    UIImage *bgImage = nil;
    
    //左侧
    if (![sender isEqualToString:@"you"])
    {
        left = KLEFT;
        
        bgImage = [[UIImage imageNamed:@"duihuahuang"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        
        dix = 10 - 5;
        
    }else
    {
        left = self.width - KLEFT - OHLabel.width - 3 * KDIS;
        
        bgImage = [[UIImage imageNamed:@"duihuahuang1"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        
        dix = -10 + 5;
    }
    
    
//    float sysVersion = [[[UIDevice currentDevice]systemVersion] floatValue];
//    UIImage *image;//气泡图片
//    if (sysVersion < 5.0) {
//        if (indexPath.row % 2 == 0) {
//            image = [[UIImage imageNamed:@"chat_receive_nor.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:30];
//        }else {
//            image = [[UIImage imageNamed:@"chat_send_nor.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:30];
//        }
//    }else {
//        if (indexPath.row % 2 == 0) {
//            image = [[UIImage imageNamed:@"chat_receive_nor.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(30, 20, 10, 20)];
//        }else {
//            image = [[UIImage imageNamed:@"chat_send_nor.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(30, 20, 10, 20)];
//        }
//    }
    
    self.bgImageView.image = bgImage;
    [self.bgImageView setFrame:CGRectMake(left, KDIS + self.senderAndTimeLabel.height, aSize.width + 2 * KDIS, aSize.height + KDIS)];
    self.OHLabel.center = CGPointMake(bgImageView.width / 2.0 + dix, bgImageView.height / 2.0);
    
}



@end
