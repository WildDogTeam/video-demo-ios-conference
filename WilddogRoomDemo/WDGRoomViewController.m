//
//  WDGRoomViewController.m
//  WilddogRoomDemo
//
//  Created by Hayden on 2017/9/1.
//  Copyright © 2017 Wilddog. All rights reserved.
//

#import <WilddogCore/WilddogCore.h>
#import <WilddogVideoRoom/WilddogVideoRoom.h>
#import <WilddogVideoBase/WilddogVideoBase.h>

#import "WDGRoomViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoCollectionViewCell.h"


@interface WDGRoomViewController () <WDGRoomDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) WDGRoom *room;
@property (nonatomic, strong) WDGVideoView *localView;
@property (nonatomic, strong) WDGLocalStream *localStream;
@property (nonatomic, strong) NSMutableArray<WDGStream *> *streams;

@property (nonatomic, weak) IBOutlet UICollectionView *grid;
@property (nonatomic, weak) IBOutlet UIButton *audioSwitch;
@property (nonatomic, weak) IBOutlet UIButton *videoSwitch;
@property (nonatomic, assign) BOOL audioOn;
@property (nonatomic, assign) BOOL videoOn;

@end

@implementation WDGRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    _streams = [[NSMutableArray alloc] init];
    
    // 配置 UICollectionView
    [self setupCollectionView];
    // 创建并预览本地流
    [self setupLocalStream];
    // 创建或加入房间
    _room = [[WDGRoom alloc] initWithRoomId:_roomId domain:@"bt-sh.wilddog.com" delegate:self];
//    _room = [[WDGRoom alloc] initWithRoomId:_roomId domain:@"10.18.6.64" delegate:self];

    [_room connect];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.title = self.roomId;
    self.audioOn = YES;
    self.videoOn = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)didSessionRouteChange:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonCategoryChange: {
            // Set speaker as default route
            NSError* error;
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        }
            break;
        default:
            break;
    }
}


#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.streams.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"CELL";
    VideoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.layer.cornerRadius = 10;
    cell.layer.masksToBounds = YES;
    if (indexPath.row == 0) {
        cell.videoView.mirror = YES;
        self.localView = cell.videoView;
    }
    cell.videoView.contentMode = UIViewContentModeScaleAspectFill;
    [self.streams[indexPath.row] attach:cell.videoView];
    return cell;
}

#pragma mark - Client Operation

- (void)publishLocalStream {
    if (self.localStream) {
        [self.room publishLocalStream:self.localStream withCompletionBlock:^(NSError * _Nullable error) {
            NSLog(@"Publish Completion Block");
        }];
    }
}

- (void)unpublishLocalStream {
    if (self.localStream) {
        [self.room unpublishLocalStream:self.localStream withCompletionBlock:^(NSError * _Nullable error) {
            NSLog(@"Unpublish Completion Block");
        }];
    }
}

- (void)subscribeRoomStream:(WDGRoomStream *)roomStream {
    if (roomStream) {
        [self.room subscribeRoomStream:roomStream withCompletionBlock:^(NSError * _Nullable error) {
            NSLog(@"Subscribe Completion Block");
        }];
    }
}

- (void)unsubscribeRoomStream:(WDGRoomStream *)roomStream {
    if (roomStream) {
        [self.room unsubscribeRoomStream:roomStream withCompletionBlock:^(NSError * _Nullable error) {
            NSLog(@"Unsubscribe Completion Block");
        }];
    }
}


#pragma mark - WDGRoomDelegate

- (void)wilddogRoomDidConnect:(WDGRoom *)wilddogRoom {
    NSLog(@"Room Connected!");
    // 发布本地流
    [self publishLocalStream];
}

- (void)wilddogRoomDidDisconnect:(WDGRoom *)wilddogRoom {
    NSLog(@"Room Disconnected!");
    //__weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        //__strong __typeof__(self) strongSelf = weakSelf;
        NSLog(@"Disconnected!");
        [self dismissViewControllerAnimated:YES completion:NULL];
    });
}

- (void)wilddogRoom:(WDGRoom *)wilddogRoom didStreamAdded:(WDGRoomStream *)roomStream {
    NSLog(@"RoomStream Added!");
    [self subscribeRoomStream:roomStream];
}

- (void)wilddogRoom:(WDGRoom *)wilddogRoom didStreamRemoved:(WDGRoomStream *)roomStream {
    NSLog(@"RoomStream Removed!");
    [self unsubscribeRoomStream:roomStream];
    [self.streams removeObject:roomStream];
    [self.grid reloadData];
}

- (void)wilddogRoom:(WDGRoom *)wilddogRoom didStreamReceived:(WDGRoomStream *)roomStream {
    NSLog(@"RoomStream Received!");
    [self.streams addObject:roomStream];
    [self.grid reloadData];
}

- (void)wilddogRoom:(WDGRoom *)wilddogRoom didFailWithError:(NSError *)error {
    NSLog(@"Room Failed: %@", error);
    if (error) {
        NSString *errorMessage = [NSString stringWithFormat:@"会议错误: %@", [error localizedDescription]];
        [self showAlertWithTitle:@"提示" message:errorMessage];
    }
}

#pragma mark - Internal methods

- (void)setupLocalStream {
    // 创建本地流
    WDGLocalStreamOptions *localStreamOptions = [[WDGLocalStreamOptions alloc] init];
    localStreamOptions.shouldCaptureAudio = YES;
    localStreamOptions.dimension = self.dimension;
    self.localStream = [WDGLocalStream localStreamWithOptions:localStreamOptions];
    [self.streams addObject:self.localStream];
    [self.grid reloadData];
}

- (void)setupCollectionView {
    self.grid.dataSource = self;
    self.grid.delegate = self;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat width = (self.view.bounds.size.width - 24) / 2;
    CGFloat height = (self.view.bounds.size.height - 162) / 3;
    flowLayout.itemSize = CGSizeMake(width, height);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    flowLayout.minimumLineSpacing = 8;
    flowLayout.minimumInteritemSpacing = 0;
    self.grid.collectionViewLayout = flowLayout;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Action Buttons
- (IBAction)recording:(id)sender {
    UIBarButtonItem *item = sender;
    if (item.tag == 0) {
        NSLog(@"recording event");
        [self.room startRecordingWithOptions:@{ @"fps" : @15,
                                                @"bitrate" : @300,
                                                @"canvasWidth" : @1000,
                                                @"canvasHeight" : @1000,
                                                @"bgColor" : @0x000000ff}
                             completionBlock:^(NSString * _Nonnull url, NSError * _Nullable error) {
                                 NSLog(@"record filename: \n%@",url);
                                 item.tag = 1;
                             }];
    } else {
        NSLog(@"stop recording event");
        [self.room stopRecordingWithCompletionBlock:^(NSError * _Nullable error) {
            NSLog(@"recording stopped");
            item.tag = 0;
        }];
    }
}

- (IBAction)switchCameraButtonTapped:(id)sender {
    [self.localStream switchCamera];
    self.localView.mirror = !self.localView.mirror;
    //self.attachedViews[self.uid].mirror = !self.attachedViews[self.uid].mirror;
}

- (IBAction)toggleMicrophone:(id)sender {
    self.localStream.audioEnabled = !self.localStream.audioEnabled;
    self.audioOn = !self.audioOn;
    [self.audioSwitch setTitle:self.audioOn?@"音频开":@"音频关" forState:UIControlStateNormal];
    [self.audioSwitch setTitleColor:self.audioOn?[UIColor colorWithRed:0 green:0.5 blue:0 alpha:1]:[UIColor redColor] forState:UIControlStateNormal];
}

- (IBAction)toggleVideo:(id)sender {
    self.localStream.videoEnabled = !self.localStream.videoEnabled;
    self.videoOn = !self.videoOn;
    [self.videoSwitch setTitle:self.videoOn?@"视频开":@"视频关" forState:UIControlStateNormal];
    [self.videoSwitch setTitleColor:self.videoOn?[UIColor colorWithRed:0 green:0.5 blue:0 alpha:1]:[UIColor redColor] forState:UIControlStateNormal];
}

- (IBAction)disconnect:(id)sender {
    [self.room disconnect];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
