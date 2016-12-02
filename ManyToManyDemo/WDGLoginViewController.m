//
//  WDGLoginViewController.m
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogSync/WilddogSync.h>
#import <WilddogAuth/WilddogAuth.h>
#import <WilddogVideo/WilddogVideo.h>

#import "WDGLoginViewController.h"
#import "WDGMainViewController.h"

@interface WDGLoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *appIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation WDGLoginViewController

- (IBAction)loginButtonTapped:(id)sender
{
    self.loginButton.enabled = NO;

    // 配置 WDGApp
    NSString *appID = self.appIDTextField.text;
    WDGOptions *options = [[WDGOptions alloc] initWithSyncURL:[NSString stringWithFormat:@"https://%@.wilddogio.com", appID]];
    [WDGApp configureWithOptions:options];

    // 匿名登录
    [[WDGAuth auth] signOut:nil];
    __weak __typeof__(self) weakSelf = self;
    [[WDGAuth auth] signInAnonymouslyWithCompletion:^(WDGUser *user, NSError *error) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (error != nil) {
            NSLog(@"登录错误: %@", error);
            strongSelf.loginButton.enabled = YES;
            return;
        }

        WDGVideoClient *videoClient = [[WDGVideoClient alloc] initWithApp:[WDGApp defaultApp]];

        if (videoClient == nil) {
            NSLog(@"创建 WDGVideoClient 失败");
            strongSelf.loginButton.enabled = YES;
            return;
        }

        // 登录成功，进入主界面
        UINavigationController *mainNavigationController = [strongSelf.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
        WDGMainViewController *mainViewController = mainNavigationController.viewControllers.firstObject;
        mainViewController.videoClient = videoClient;
        [strongSelf presentViewController:mainNavigationController animated:YES completion:NULL];

        strongSelf.loginButton.enabled = YES;
    }];
}

@end
