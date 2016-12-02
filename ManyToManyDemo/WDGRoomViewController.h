//
//  WDGRoomViewController.h
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WDGUser;
@class WDGVideoConversation;

@interface WDGRoomViewController : UIViewController <WDGVideoConversationDelegate>

@property (nonatomic, strong) WDGVideoClient *videoClient;
@property (nonatomic, strong) NSString *conferenceID;

@end
