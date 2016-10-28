//
//  WDGRoomViewController.m
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <WilddogAuth/WilddogAuth.h>
#import <WilddogVideo/WilddogVideo.h>

#import "WDGRoomViewController.h"
#import "WDGInviteViewController.h"

@interface WDGRoomViewController () <WDGInviteViewControllerDelegate>

@property (nonatomic, weak) IBOutlet WDGVideoView *centerVideoView;
@property (nonatomic, weak) IBOutlet UIStackView *remoteStackView;

@property (nonatomic, strong) NSMutableDictionary<NSString *, WDGVideoView *> *attachedViews;

@end

@implementation WDGRoomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.attachedViews = [[NSMutableDictionary<NSString *, WDGVideoView *> alloc] init];

    self.centerVideoView.contentMode = UIViewContentModeScaleAspectFill;
    [self.videoConversation.localStream attach:self.centerVideoView];
}

#pragma mark - Actions

- (IBAction)flipCameraButtonTapped:(id)sender
{
    // 翻转摄像头
    [self.videoConversation.localStream flipCamera];
}

- (IBAction)toggleMicrophone:(id)sender
{
    // 切换麦克风录音开关
    self.videoConversation.localStream.audioEnabled = !self.videoConversation.localStream.audioEnabled;
}

- (IBAction)toggleVideo:(id)sender
{
    // 切换视频开关
    self.videoConversation.localStream.videoEnabled = !self.videoConversation.localStream.videoEnabled;
}

- (IBAction)invite:(id)sender
{
    // 展示邀请界面，排除当前参与者
    NSMutableArray<NSString *> *excludedUserList = [[self.videoConversation.participants valueForKey:@"participantID"] mutableCopy];
    [excludedUserList addObject:self.user.uid];

    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"userListNavigationController"];
    WDGInviteViewController *inviteViewController = navigationController.viewControllers.firstObject;
    inviteViewController.delegate = self;
    inviteViewController.excludedUsers = [[NSSet<NSString * > alloc] initWithArray:excludedUserList];
    inviteViewController.videoReference = self.videoReference;
    inviteViewController.buttonString = @"邀请加入";

    [self presentViewController:navigationController animated:YES completion:NULL];
}

- (IBAction)disconnect:(id)sender
{
    [self.videoConversation disconnect];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - WDGInviteViewControllerDelegate

- (void)inviteViewController:(WDGInviteViewController *)viewController didDissmissedWithInvitingUserID:(NSString *)userID
{
    // 邀请其他用户加入当前会议
    NSError *error = nil;
    if (![self.videoConversation inviteWithParticipantID:userID error:&error]) {
        NSLog(@"未能邀请用户，错误信息：%@", error);
    }
}

#pragma mark - WDGVideoConversationDelegate

- (void)conversation:(WDGVideoConversation *)conversation didConnectParticipant:(WDGVideoParticipant *)participant
{
    // 连接参与者，寻找可用的 WDGVideoView，并与其绑定
    for (WDGVideoView *view in [self.remoteStackView.arrangedSubviews reverseObjectEnumerator]) {
        if (![self.attachedViews.allValues containsObject:view]) {
            WDGVideoRemoteStream *stream = participant.stream;
            [stream attach:view];
            view.hidden = NO;
            self.attachedViews[participant.participantID] = view;
            return;
        }
    }
}

- (void)conversation:(WDGVideoConversation *)conversation didFailToConnectParticipant:(WDGVideoParticipant *)participant error:(NSError *)error
{
    // 检查是否应该结束会话
    if (conversation.participants.count == 0) {
        [self disconnect:nil];
    }
}

- (void)conversation:(WDGVideoConversation *)conversation didDisconnectParticipant:(WDGVideoParticipant *)participant
{
    WDGVideoView *attachedView = self.attachedViews[participant.participantID];

    // 参与者离线，解绑并隐藏 WDGVideoView
    if (attachedView != nil) {
        [participant.stream detach:attachedView];
        attachedView.hidden = YES;
        [self.attachedViews removeObjectForKey:participant.participantID];
    }

    // 检查是否应该结束会话
    if (conversation.participants.count == 0) {
        [self disconnect:nil];
    }
}

@end
