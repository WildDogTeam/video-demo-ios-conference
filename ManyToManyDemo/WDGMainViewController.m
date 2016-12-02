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
#import "WDGRoomViewController.h"

@interface WDGMainViewController ()

@property (nonatomic, weak) IBOutlet UITextField *meetingIDTextField;
@property (nonatomic, weak) IBOutlet UIButton *connectButton;

@end

@implementation WDGMainViewController

- (IBAction)connectButtonDidTapped:(id)sender
{
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"roomNavigationController"];
    WDGRoomViewController *roomViewController = navigationController.viewControllers.firstObject;
    roomViewController.videoClient = self.videoClient;
    roomViewController.conferenceID = self.meetingIDTextField.text;

    [self presentViewController:navigationController animated:YES completion:NULL];
}

@end
