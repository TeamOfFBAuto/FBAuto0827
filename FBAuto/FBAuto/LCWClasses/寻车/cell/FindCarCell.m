//
//  FindCarCell.m
//  FBAuto
//
//  Created by lichaowei on 14-7-18.
//  Copyright (c) 2014年 szk. All rights reserved.
//

#import "FindCarCell.h"
#import "CarSourceClass.h"

@implementation FindCarCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellDataWithModel:(CarSourceClass *)aCar
{
    //@"发河北 寻美规 奥迪Q7 14款 豪华"
    NSString *contentText = [NSString stringWithFormat:@"寻%@",aCar.car_name];
    self.contentLabel.text = contentText;
    
    NSString *area = [NSString stringWithFormat:@"发%@%@",aCar.province,aCar.city];
    
    if ([area isEqualToString:@"发不限不限"]) {
        area = @"发不限";
    }
    
    self.toAddressLabel.text = area;
    
    self.moneyLabel.text = [self depositWithText:aCar.deposit];
    self.nameLabel.text = aCar.username;
    self.timeLabel.text = [LCWTools timechange:aCar.dateline];
}

- (NSString *)depositWithText:(NSString *)text
{
    if ([text isEqualToString:@"1"]) {
        text = @"定金已付";
    }else if ([text isEqualToString:@"2"])
    {
        text = @"定金未支付";
    }else if ([text isEqualToString:@"0"] || [text isEqualToString:@""])
    {
        text = @"定金不限";
    }
    return text;
}

@end
