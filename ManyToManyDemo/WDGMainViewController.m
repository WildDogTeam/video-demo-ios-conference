//
//  WDGMainViewController.m
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <WilddogAuth/WilddogAuth.h>
#import <WilddogSync/WilddogSync.h>
#import <WilddogVideo/WilddogVideo.h>

#import "WDGMainViewController.h"
#import "WDGInviteViewController.h"
#import "WDGRoomViewController.h"

@interface WDGMainViewController () <WDGVideoClientDelegate, WDGInviteViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *userIDLabel;
@property (nonatomic, weak) IBOutlet WDGVideoView *localStreamPreviewView;
@property (nonatomic, weak) IBOutlet UIButton *bottomButton;

@property (nonatomic, strong) WDGVideoLocalStream *localStream;
@property (nonatomic, strong) WDGVideoOutgoingInvite *outgoingInvite;

@end

@implementation WDGMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.userIDLabel.text = self.user.uid;

    // 将自己加入在线用户列表，以便于其他用户邀请
    [[[[self.videoReference root] child:@"users"] child:self.user.uid] setValue:@YES];
    [[[[self.videoReference root] child:@"users"] child:self.user.uid] onDisconnectRemoveValue];

    // 创建并预览本地视频流
    self.localStreamPreviewView.contentMode = UIViewContentModeScaleAspectFill;
    WDGVideoLocalStreamConfiguration *configuration = [[WDGVideoLocalStreamConfiguration alloc] initWithVideoOption:WDGVideoConstraintsStandard audioOn:YES];
    self.localStream = [self.videoClient localStreamWithConfiguration:configuration];
    [self.localStream attach:self.localStreamPreviewView];

    // 将自己设为代理以接收邀请
    self.videoClient.delegate = self;
}

#pragma mark - Actions

- (IBAction)bottomButtonDidTapped:(id)sender
{
    if (self.outgoingInvite == nil) {
        // 当前未进行邀请，展示邀请窗口
        UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"userListNavigationController"];
        WDGInviteViewController *inviteViewController = navigationController.viewControllers.firstObject;
        inviteViewController.delegate = self;
        inviteViewController.excludedUsers = [[NSSet<NSString *> alloc] initWithObjects:self.user.uid, nil];
        inviteViewController.videoReference = self.videoReference;
        inviteViewController.buttonString = @"发起会话";

        [self presentViewController:navigationController animated:YES completion:NULL];
    } else {
        // 当前正在邀请，取消邀请
        self.bottomButton.titleLabel.text = @"发起会话";
        [self.outgoingInvite cancel];
        self.outgoingInvite = nil;
    }
}

#pragma mark - WDGInviteViewControllerDelegate

- (void)inviteViewController:(WDGInviteViewController *)viewController didDissmissedWithInvitingUserID:(NSString *)userID
{
    self.bottomButton.titleLabel.text = @"正在邀请中，点击取消会话";
    __weak __typeof__(self) weakSelf = self;
    self.outgoingInvite = [self.videoClient inviteUser:userID localStream:self.localStream conversationMode:WDGVideoConversationModeServerBased completion:^(WDGVideoConversation *conversation, NSError *error) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (error != nil) {
            if ([error.domain isEqualToString:WDGVideoErrorDomain] && error.code == WDGVideoErrorCodeConversationRejected) {
                // 对方拒绝邀请
                NSString *message = [NSString stringWithFormat:@"%@\n拒绝了邀请", userID];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:NULL]];
                [strongSelf presentViewController:alertController animated:YES completion:NULL];

                strongSelf.bottomButton.titleLabel.text = @"发起会话";
                strongSelf.outgoingInvite = nil;
                return;
            }

            // 其他错误
            strongSelf.bottomButton.titleLabel.text = @"发起会话";
            strongSelf.outgoingInvite = nil;
            NSLog(@"邀请失败，错误信息: %@", error);
            return;
        }

        // 对方接受邀请，进入会话房间
        UINavigationController *navigationViewController = [strongSelf.storyboard instantiateViewControllerWithIdentifier:@"roomNavigationController"];
        WDGRoomViewController *roomViewController = navigationViewController.viewControllers.firstObject;
        roomViewController.user = strongSelf.user;
        roomViewController.videoConversation = conversation;
        conversation.delegate = roomViewController;
        roomViewController.videoReference = strongSelf.videoReference;
        [strongSelf presentViewController:navigationViewController animated:YES completion:NULL];

        strongSelf.bottomButton.titleLabel.text = @"发起会话";
        strongSelf.outgoingInvite = nil;
    }];
}

#pragma mark - WDGVideoClientDelegate

- (void)wilddogVideoClient:(WDGVideoClient *)videoClient didReceiveInvite:(WDGVideoIncomingInvite *)invite
{
    NSString *message = [NSString stringWithFormat:@"%@\n邀请你加入会话", invite.fromUserID];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];

    __weak __typeof__(self) weakSelf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [invite acceptWithLocalStream:self.localStream completion:^(WDGVideoConversation *conversation, NSError *error) {
            __strong __typeof__(self) strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            if (error != nil) {
                NSLog(@"未能接受邀请，错误信息: %@", error);
                return;
            }

            // 成功接受邀请，进入会话房间
            UINavigationController *navigationViewController = [strongSelf.storyboard instantiateViewControllerWithIdentifier:@"roomNavigationController"];
            WDGRoomViewController *roomViewController = navigationViewController.viewControllers.firstObject;
            roomViewController.user = strongSelf.user;
            roomViewController.videoConversation = conversation;
            conversation.delegate = roomViewController;
            roomViewController.videoReference = strongSelf.videoReference;
            [strongSelf presentViewController:navigationViewController animated:YES completion:NULL];
        }];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [invite reject];
    }]];

    [self presentViewController:alertController animated:YES completion:NULL];
}

- (void)wilddogVideoClient:(WDGVideoClient *)videoClient inviteDidCancel:(WDGVideoIncomingInvite *)invite
{
    if (self.presentedViewController != nil && [self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        // 邀请方取消邀请，如果当前正在展示选择是否接受邀请的弹窗，则将其隐藏
        __weak __typeof__(self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            __strong __typeof__(self) strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            NSString *message = [NSString stringWithFormat:@"%@\n取消了邀请", invite.fromUserID];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:NULL]];
            [strongSelf presentViewController:alertController animated:YES completion:NULL];
        }];
    }
}

@end
