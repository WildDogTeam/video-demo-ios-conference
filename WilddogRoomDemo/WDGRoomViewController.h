//
//  WDGRoomViewController.h
//  WilddogRoomDemo
//
//  Created by Hayden on 2017/9/1.
//  Copyright © 2017 Wilddog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WDGRoomViewController : UIViewController

@property (nonatomic, strong) NSString *roomId;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, assign) WDGVideoDimensions dimension;

@end
