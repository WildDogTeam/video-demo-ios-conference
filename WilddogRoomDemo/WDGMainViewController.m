//
//  WDGMainViewController.m
//  WilddogRoomDemo
//
//  Created by Hayden on 2017/9/1.
//  Copyright © 2017 Wilddog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogAuth/WilddogAuth.h>
#import <WilddogVideoBase/WilddogVideoBase.h>
#import "WDGMainViewController.h"
#import "WDGRoomViewController.h"

@interface WDGMainViewController ()

@property (nonatomic, weak) IBOutlet UITextField *roomIdTextField;
@property (nonatomic, weak) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *resolutionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *frameControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fpsControl;

@end

@implementation WDGMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Maybe login here.
}

- (IBAction)joinButtonDidTapped:(id)sender {
    self.joinButton.enabled = NO;
    
    // 配置 Wilddog App
    NSString *appID = @"wildrtc";
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
        if (error) {
            NSLog(@"请在控制台为您的AppID开启匿名登录功能，错误信息: %@", error);
            return;
        }
        // 获取 token 并配置 WilddogVideoInitializer
        [user getTokenWithCompletion:^(NSString * _Nullable idToken, NSError * _Nullable error) {
            // 配置 Video Initializer
            [[WDGVideoInitializer sharedInstance] configureWithVideoAppId:appID token:idToken];
            // 页面传值
            UINavigationController *navigationController = [strongSelf.storyboard instantiateViewControllerWithIdentifier:@"roomNavigationController"];
            WDGRoomViewController *roomViewController = navigationController.viewControllers.firstObject;
            // 传递获得的 roomId，如果不输入，默认为 'your_room_id'
            NSString *roomId = @"roomid";
            if (![self.roomIdTextField.text isEqualToString:@""]) {
                roomId = self.roomIdTextField.text;
            }
            roomViewController.roomId = roomId;
            roomViewController.uid = user.uid;
            switch (self.resolutionControl.selectedSegmentIndex) {
                case 0:
                    roomViewController.dimension = WDGVideoDimensions360p;
                    break;
                case 1:
                    roomViewController.dimension = WDGVideoDimensions480p;
                    break;
                case 2:
                    roomViewController.dimension = WDGVideoDimensions720p;
                    break;
                default:
                    roomViewController.dimension = WDGVideoDimensions360p;
                    break;
            }
            switch (self.frameControl.selectedSegmentIndex) {
                case 0:
                    roomViewController.frame = 6;
                    break;
                case 1:
                    roomViewController.frame = 4;
                    break;
                default:
                    roomViewController.frame = 1;
                    break;
            }
            switch (self.fpsControl.selectedSegmentIndex) {
                case 0:
                    roomViewController.fps = 15;
                    break;
                default:
                    roomViewController.fps = 30;
                    break;
            }
            [self presentViewController:navigationController animated:YES completion:NULL];
            strongSelf.joinButton.enabled = YES;
        }];
    }];
}

@end
