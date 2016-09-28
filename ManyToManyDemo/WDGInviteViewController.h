//
//  WDGInviteViewController.h
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WDGUser;
@class WDGSyncReference;
@protocol WDGInviteViewControllerDelegate;

@interface WDGInviteViewController : UIViewController

@property (nonatomic, strong) NSSet<NSString *> *excludedUsers;
@property (nonatomic, strong) WDGSyncReference *videoReference;
@property (nonatomic, strong) NSString *buttonString;

@property (nonatomic, weak) id<WDGInviteViewControllerDelegate> delegate;

@end

@protocol WDGInviteViewControllerDelegate <NSObject>

- (void)inviteViewController:(WDGInviteViewController *)viewController didDissmissedWithInvitingUserID:(NSString *)userID;

@end
