//
//  WDGRoomViewController.m
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogVideo/WilddogVideo.h>

#import "WDGRoomViewController.h"

@interface WDGRoomViewController () <WDGVideoConferenceDelegate, WDGVideoParticipantDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, WDGVideoView *> *attachedViews;
@property (strong, nonatomic) IBOutletCollection(WDGVideoView) NSArray *videoViews;

@property (nonatomic, strong) WDGVideoLocalStream *localStream;
@property (nonatomic, strong) WDGVideoConference *conference;

@end

@implementation WDGRoomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.conferenceID;

    self.attachedViews = [[NSMutableDictionary<NSString *, WDGVideoView *> alloc] init];

    [self setupLocalStream];

    WDGVideoConnectOptions *connectOptions = [[WDGVideoConnectOptions alloc] initWithLocalStream:self.localStream];

    self.conference = [self.videoClient connectToConferenceWithID:self.conferenceID options:connectOptions delegate:self];
}

- (void)setupLocalStream
{
    WDGVideoLocalStreamOptions *localStreamOptions = [[WDGVideoLocalStreamOptions alloc] init];
    localStreamOptions.videoOption = WDGVideoConstraintsHigh;

    self.localStream = [[WDGVideoLocalStream alloc] initWithOptions:localStreamOptions];

    WDGVideoView *videoView = self.videoViews.firstObject;
    self.attachedViews[self.videoClient.uid] = videoView;
    [self.localStream attach:videoView];
}

- (void)attachStreamFromParticipant:(WDGVideoParticipant *)participant
{
    for (WDGVideoView *view in self.videoViews) {
        if (![self.attachedViews.allValues containsObject:view]) {
            self.attachedViews[participant.ID] = view;
            [participant.stream attach:view];
            return;
        }
    }
}

- (void)detachStreamFromParticipant:(WDGVideoParticipant *)participant
{
    // 参与者离线，解绑并隐藏 WDGVideoView
    WDGVideoView *attachedView = self.attachedViews[participant.ID];
    if (attachedView != nil) {
        [self.attachedViews removeObjectForKey:participant.ID];
        [participant.stream detach:attachedView];
    }
}

#pragma mark - Actions

- (IBAction)switchCameraButtonTapped:(id)sender
{
    // 翻转摄像头
    [self.localStream switchCamera];
}

- (IBAction)toggleMicrophone:(id)sender
{
    // 切换麦克风录音开关
    self.localStream.audioEnabled = !self.localStream.audioEnabled;
}

- (IBAction)toggleVideo:(id)sender
{
    // 切换视频开关
    self.localStream.videoEnabled = !self.localStream.videoEnabled;
}

- (IBAction)disconnect:(id)sender
{
    [self.conference disconnect];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - WDGVideoConferenceDelegate

- (void)conferenceDidConnected:(WDGVideoConference *)conference
{
    NSLog(@"Conference connected");
}

- (void)conference:(WDGVideoConference *)conference didFailedToConnectWithError:(NSError *)error
{
    NSLog(@"Conference failed to connect with error: %@", error);
    if (error != nil) {
        NSString *errorMessage = [NSString stringWithFormat:@"会议错误: %@", [error localizedDescription]];
        [self showAlertWithTitle:@"提示" message:errorMessage];
    }
}

- (void)conference:(WDGVideoConference *)conference didDisconnectWithError:(NSError *)error
{
    NSLog(@"Conference disconnected with error: %@", error);
}

- (void)conference:(WDGVideoConference *)conference didConnectParticipant:(WDGVideoParticipant *)participant
{
    NSLog(@"Conference connect participant %@", participant.ID);
    participant.delegate = self;
}

- (void)conference:(WDGVideoConference *)conference didDisconnectParticipant:(WDGVideoParticipant *)participant
{
    NSLog(@"Conference disconnect participant %@", participant.ID);
    [self detachStreamFromParticipant:participant];
}

#pragma mark - WDGVideoParticipant

- (void)participant:(WDGVideoParticipant *)participant didAddStream:(WDGVideoRemoteStream *)stream
{
    NSLog(@"Participant %@ addStream", participant);
    [self attachStreamFromParticipant:participant];
}

- (void)participant:(WDGVideoParticipant *)participant didFailedToConnectWithError:(NSError *)error
{
    NSLog(@"Failed to connect participant: %@ error: %@", participant.ID, error);
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
