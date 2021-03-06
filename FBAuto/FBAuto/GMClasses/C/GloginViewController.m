//
//  GloginViewController.m
//  FBAuto
//
//  Created by gaomeng on 14-7-1.
//  Copyright (c) 2014年 szk. All rights reserved.
//

#import "GloginViewController.h"
#import "GloginView.h"//登录界面view
#import "GzhuceViewController.h"//注册
#import "GfindPasswViewController.h"//找回密码

#import "XMPPStatics.h"
#import "XMPPServer.h"

@interface GloginViewController ()

@end

@implementation GloginViewController



-(void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}


-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = YES;
}





//-(void)viewDidAppear:(BOOL)animated{
//
//    [super viewDidAppear:animated];
//    //隐藏navigationBar
//    self.navigationController.navigationBarHidden = YES;
//
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //self.button_back.hidden = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"%s",__FUNCTION__);
    
    GloginView *gloginView = [[GloginView alloc]initWithFrame:CGRectMake(0, 0, 320, iPhone5?568:480)];
    self.gloginView = gloginView;
    [self.view addSubview:gloginView];
    
    
    __weak typeof (self)bself = self;
    __weak typeof (gloginView)bgloginView = gloginView;
    
    //设置跳转注册block
    [gloginView setZhuceBlock:^{
        [bgloginView Gshou];
        [bself pushToZhuceVC];
    }];
    
    //设置找回密码block
    [gloginView setFindPassBlock:^{
        [bgloginView Gshou];
        [bself pushToFindPassWordVC];
    }];
    
    //登录
    [gloginView setDengluBlock:^(NSString *usern, NSString *passw) {
        
        NSLog(@"--%@     --%@",usern,passw);
        
        if (usern.length ==0 && passw.length == 0) {
            UIAlertView *al = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请输入用户名和密码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [al show];
        }else if (usern.length == 0 || passw.length == 0){
            if (usern.length == 0) {
                UIAlertView *al = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请输入用户名" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [al show];
            }else if (passw.length == 0){
                UIAlertView *al = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请输入密码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [al show];
            }
        }else{
            [bself dengluWithUserName:usern pass:passw];
        }
        
        
    }];
    
}






#pragma mark - 登录
-(void)dengluWithUserName:(NSString *)name pass:(NSString *)passw{
    //菊花
    UIActivityIndicatorView *j = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    j.center = CGPointMake(160, 235);
    [self.view addSubview:j];
    [j startAnimating];
    
    NSString *deviceToken = [GMAPI getDeviceToken] ? [GMAPI getDeviceToken] : @"testToken";
    
    NSString *str = [NSString stringWithFormat:FBAUTO_LOG_IN,name,passw,deviceToken];
    
    //保存用户手机号
    [[NSUserDefaults standardUserDefaults]setObject:name forKey:USERPHONENUMBER];
    
    NSLog(@"登录请求接口======%@",str);
    
    NSURL *url = [NSURL URLWithString:str];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        
        NSLog(@"error-----------%@",connectionError);
        
        [j stopAnimating];
        if ([data length] == 0) {
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@ %@",dic,[dic objectForKey:@"errinfo"]);
        
        
        
        if ([[dic objectForKey:@"errcode"] intValue] == 0) {
            
            NSDictionary *datainfo = [dic objectForKey:@"datainfo"];
            NSString *userid = [datainfo objectForKey:@"uid"];
            NSString *username = [datainfo objectForKey:@"name"];
            NSString *authkey = [datainfo objectForKey:@"authkey"];
            NSString *open = [datainfo objectForKey:@"open"];
                        
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            
            //聊天使用
            
            [defaults setObject:name forKey:XMPP_USERID];
            
            [defaults setObject:open forKey:XMPP_PASS];
            
            
//            [defaults setObject:@"60.18.147.4" forKey:XMPP_SERVER];
            
            [defaults setObject:userid forKey:USERID];
            [defaults setObject:username forKey:USERNAME];
            [defaults setObject:authkey forKey:USERAUTHKEY];
            [defaults setObject:passw forKey:USERPASSWORD];
            [defaults synchronize];
            
            
//            [[XMPPServer shareInstance]loginTimes:10 loginBack:^(BOOL result) {
//                if (result) {
//                    NSLog(@"连接并且登录成功");
//                }else{
//                    NSLog(@"连接登录不成功");
//                }
//            }];
            
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        }else{
            UIAlertView *al = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请核对用户名或密码是否正确" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [al show];
        }
        
        
    }];
    
    
}



#pragma mark - 跳转到注册界面
-(void)pushToZhuceVC{
    GzhuceViewController *gzhuceVc = [[GzhuceViewController alloc]init];
    [self.navigationController pushViewController:gzhuceVc animated:YES];
}

#pragma mark - 跳转找回密码界面
-(void)pushToFindPassWordVC{
    GfindPasswViewController *gfindwVc = [[GfindPasswViewController alloc]init];
    [self.navigationController pushViewController:gfindwVc animated:YES];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
