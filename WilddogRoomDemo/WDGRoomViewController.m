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
#import <mach/mach.h>


#define RecordPathTitle @"视频路径"


@interface WDGRoomViewController () <WDGRoomDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) WDGRoom *room;
@property (nonatomic, strong) WDGVideoView *localView;
@property (nonatomic, strong) WDGLocalStream *localStream;
@property (nonatomic, strong) NSMutableArray<WDGStream *> *streams;

@property (nonatomic, weak) IBOutlet UICollectionView *grid;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *audioSwitch;
@property (nonatomic, weak) IBOutlet UIButton *videoSwitch;
@property (nonatomic, assign) BOOL audioOn;
@property (nonatomic, assign) BOOL videoOn;
@property (nonatomic, strong) __block NSString *recordUrl;
@property (weak, nonatomic) IBOutlet UILabel *systemResourceLabel;

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
    // 打开控制台日志（可选）
    [WDGVideoInitializer sharedInstance].userLogLevel = WDGVideoLogLevelError;
    // 创建或加入房间
    _room = [[WDGRoom alloc] initWithRoomId:_roomId delegate:self];
//    _room = [[WDGRoom alloc] initWithRoomId:_roomId url:@"bt-sh-test.wilddog.com" delegate:self];
    [_room connect];
    [self getSystemResourceUsage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.title = self.roomId;
    self.audioOn = YES;
    self.videoOn = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    [self.recordButton setTintColor:[UIColor colorWithRed:0 green:0.6 blue:0 alpha:1]];
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
    localStreamOptions.maxFPS = self.fps;
    self.localStream = [WDGLocalStream localStreamWithOptions:localStreamOptions];
    [self.streams addObject:self.localStream];
    [self.grid reloadData];
}

- (void)setupCollectionView {
    self.grid.dataSource = self;
    self.grid.delegate = self;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat width = (self.view.bounds.size.width - 24) / 2;
    CGFloat height = (self.view.bounds.size.height - 154 - 23) / 3;
    if (self.frame == 1) {
        width = self.view.bounds.size.width - (8*2);
        height = self.view.bounds.size.height - (20 + 44 + 8*3 + 50) - 23;
    } else if (self.frame == 4) {
        width = (self.view.bounds.size.width - 24) / 2;
        height = (self.view.bounds.size.height - 146 - 23) / 2;
    }
    self.grid.pagingEnabled = YES;
    flowLayout.itemSize = CGSizeMake(width, height);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(8, 0, 0, 0);
    flowLayout.minimumLineSpacing = 8;
    flowLayout.minimumInteritemSpacing = 0;
    self.grid.collectionViewLayout = flowLayout;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if([title isEqualToString:RecordPathTitle]){
        [alertController addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard *pastboard = [UIPasteboard generalPasteboard];
            pastboard.string        = message;
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:message]];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDestructive handler:nil]];
    }else{
        [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Action Buttons
- (IBAction)recording:(id)sender {
    UIBarButtonItem *item = sender;
    __weak __typeof__(self) weakSelf = self;
    if (item.tag == 0) {
        NSLog(@"recording event");
        [self.room startRecordingWithOptions:@{ @"fps" : @15,
                                                @"bitrate" : @300,
                                                @"canvasWidth" : @1000,
                                                @"canvasHeight" : @1000,
                                                @"bgColor" : @0x000000}
                             completionBlock:^(NSString * _Nonnull url, NSError * _Nullable error) {
                                 __strong __typeof__(self) strongSelf = weakSelf;
                                 strongSelf.recordUrl = url;
                                 item.tag = 1;
                                 NSLog(@"record filename: \n%@",url);
                             }];
        [self.recordButton setTintColor:[UIColor colorWithRed:0.8 green:0 blue:0 alpha:1]];
    } else {
        NSLog(@"stop recording event");
        [self.room stopRecordingWithCompletionBlock:^(NSError * _Nullable error) {
            __strong __typeof__(self) strongSelf = weakSelf;
            if (strongSelf.recordUrl) {
                [strongSelf showAlertWithTitle:RecordPathTitle message:self.recordUrl];
                strongSelf.recordUrl = nil;
            }
            item.tag = 0;
            NSLog(@"recording stopped");
        }];
        [self.recordButton setTintColor:[UIColor colorWithRed:0 green:0.6 blue:0 alpha:1]];
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
    [self.localStream close];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - System Resource Stats

float get_memory_usage() {
    struct task_basic_info info;
    //mach_msg_type_number_t size = sizeof(info);
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if( kerr == KERN_SUCCESS ) {
        return ((CGFloat)info.resident_size / 1000000);
    } else {
        return -1;
    }
}

float get_cpu_usage() {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0) {
        stat_thread += thread_count;
    }
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    // for each thread
    for (j = 0; j < (int)thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
    }
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    if (kr == KERN_SUCCESS) {
        return tot_cpu;
    } else {
        return -1;
    }
}

- (void)getSystemResourceUsage {
    NSString *usageReport = [NSString stringWithFormat:@"CPU: %.2f%@, Memory: %.2fMB", get_cpu_usage(), @"%", get_memory_usage()];
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        strongSelf.systemResourceLabel.text = usageReport;
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf getSystemResourceUsage];
    });
}

@end
