//
//  VideoCollectionViewCell.h
//  WilddogRoomDemo
//
//  Created by Hayden on 2017/9/14.
//  Copyright © 2017年 Wilddog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WilddogVideoBase/WilddogVideoBase.h>

@interface VideoCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet WDGVideoView *videoView;

@end
