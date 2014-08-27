//
//  Statics.m
//  XmppDemo
//
//  Created by 夏 华 on 12-7-13.
//  Copyright (c) 2012年 无锡恩梯梯数据有限公司. All rights reserved.
//

#import "XMPPStatics.h"

@implementation XMPPStatics

+(NSString *)getCurrentTime{
    
    NSDate *nowUTC = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    return [dateFormatter stringFromDate:nowUTC];
    
}

/**
 *  获取html中图片的width
 *
 *  @param string 分为 width、height
 *
 *  @return 宽度或者高度
 */

+ (CGFloat)imageValue:(NSString *)html for:(NSString*)string
{
    
    NSString *regex = [NSString stringWithFormat:@"%@=\"([^\"]+)\"",string];
    
    NSRegularExpression *regular = [[NSRegularExpression alloc]initWithPattern:regex options:NSRegularExpressionCaseInsensitive error:Nil];
    
    NSTextCheckingResult *firstMatch = [regular firstMatchInString:html options:0 range:NSMakeRange(0, [html length])];
    
    CGFloat width = 0.0f;
    
    if (firstMatch)
    {
        NSRange resultRange = [firstMatch rangeAtIndex:0];
        
        //height="195"
        NSString *result = [html substringWithRange:resultRange];
        
        if (result) {
            NSArray *arr = [result componentsSeparatedByString:@"\""];
            if (arr.count == 3) {
                width = [[arr objectAtIndex:1]floatValue];
                
                return width;
            }
        }
        
    }
    return width;
}

/**
 *  获取图片地址
 *
 */
+ (NSString *)imageUrl:(NSString *)html
{
    
    NSString *regex = [NSString stringWithFormat:@"src=\"([^\"]+)\""];
    
    NSRegularExpression *regular = [[NSRegularExpression alloc]initWithPattern:regex options:NSRegularExpressionCaseInsensitive error:Nil];
    
    NSTextCheckingResult *firstMatch = [regular firstMatchInString:html options:0 range:NSMakeRange(0, [html length])];
    
    NSString *url = @"";
    
    if (firstMatch)
    {
        NSRange resultRange = [firstMatch rangeAtIndex:0];
        
        //height="195"
        NSString *result = [html substringWithRange:resultRange];
        
        if (result) {
            NSArray *arr = [result componentsSeparatedByString:@"\""];
            if (arr.count == 3) {
                url = [arr objectAtIndex:1];
                
                return url;
            }
        }
        
    }
    return url;
}

#pragma - mark 调整imageView大小

#define IMAGE_MAX_WIDTH 200
#define IMAGE_MAX_HEIGHT 200

+ (void)updateFrameForImageView:(UIImageView *)imageView  originalWidth:(CGFloat)width originalHeight:(CGFloat)height
{
//    CGSize imageSize = aImage.size;
    CGRect aFrame = imageView.frame;
    
    //高特高
    CGFloat aHeight  = height;
    CGFloat aWidth = width;
    
    CGFloat constRation = IMAGE_MAX_WIDTH / IMAGE_MAX_HEIGHT;//image width/height
    CGFloat imageRatio = aWidth/aHeight;
    
    //宽大
    if (imageRatio >= constRation) {
        aWidth = aWidth > IMAGE_MAX_WIDTH ? IMAGE_MAX_WIDTH : aWidth;
        
        CGFloat ratio = aWidth / width;
        
        aHeight = aHeight * ratio;
    }else
    {
        aHeight = aHeight > IMAGE_MAX_HEIGHT ? IMAGE_MAX_HEIGHT : aHeight;
        
        CGFloat ratio = aHeight/ height;
        
        aWidth = aWidth * ratio;
    }
    
    
    aFrame.size.width = aWidth;
    aFrame.size.height = aHeight;
    
    imageView.frame = aFrame;

}


@end
