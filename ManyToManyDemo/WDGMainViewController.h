//
//  WDGMainViewController.h
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WDGUser;
@class WDGSyncReference;
@class WDGVideoClient;

@interface WDGMainViewController : UIViewController

@property (nonatomic, strong) WDGVideoClient *videoClient;

@end
