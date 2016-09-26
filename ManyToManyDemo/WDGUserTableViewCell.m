//
//  WDGUserTableViewCell.m
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/27/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import "WDGUserTableViewCell.h"

@implementation WDGUserTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.actionButton addTarget:self action:@selector(actionButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];

    self.actionButton.layer.borderWidth = 1.0;
    self.actionButton.layer.borderColor = [self.tintColor CGColor];
    self.actionButton.layer.cornerRadius = 4.0;
}

- (void)actionButtonDidTapped:(UIButton *)button
{
    if (self.delegate != nil) {
        [self.delegate userTableViewCellDidTappedActionButton:self];
    }
}

@end
