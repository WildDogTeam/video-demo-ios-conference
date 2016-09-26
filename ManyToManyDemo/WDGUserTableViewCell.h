//
//  WDGUserTableViewCell.h
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/27/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WDGUserTableViewCellDelegate;

@interface WDGUserTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *userIDLabel;
@property (nonatomic, weak) IBOutlet UIButton *actionButton;

@property (nonatomic, weak) id<WDGUserTableViewCellDelegate> delegate;

@end

@protocol WDGUserTableViewCellDelegate <NSObject>

- (void)userTableViewCellDidTappedActionButton:(WDGUserTableViewCell *)cell;

@end
