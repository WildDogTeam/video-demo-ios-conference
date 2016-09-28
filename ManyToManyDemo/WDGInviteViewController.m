//
//  WDGInviteViewController.m
//  ManyToManyDemo
//
//  Created by Zheng Li on 9/26/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

#import <WilddogSync/WilddogSync.h>
#import <WilddogVideo/WilddogVideo.h>

#import "WDGInviteViewController.h"
#import "WDGUserTableViewCell.h"

@interface WDGInviteViewController () <UITableViewDelegate, UITableViewDataSource, WDGUserTableViewCellDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<NSString *> *users;

@end

@implementation WDGInviteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.users = [[NSMutableArray<NSString *> alloc] init];

    // 查看当前在线用户
    __weak __typeof__(self) weakSelf = self;
    [[[self.videoReference root] child:@"users"] observeEventType:WDGDataEventTypeValue withBlock:^(WDGDataSnapshot *snapshot) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        NSMutableArray<NSString *> *onlineUsers = [[NSMutableArray<NSString *> alloc] init];

        for (WDGDataSnapshot *aUser in snapshot.children) {
            if (![strongSelf.excludedUsers containsObject:aUser.key]) {
                [onlineUsers addObject:aUser.key];
            }
        }

        strongSelf.users = onlineUsers;
        [strongSelf.tableView reloadData];
    }];
}

#pragma mark - Actions

- (IBAction)backButtonDidTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDGUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userTableViewCell" forIndexPath:indexPath];

    cell.delegate = self;
    cell.userIDLabel.text = self.users[indexPath.row];
    cell.actionButton.titleLabel.text = self.buttonString;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - WDGDelegate

- (void)userTableViewCellDidTappedActionButton:(WDGUserTableViewCell *)cell
{
    __weak __typeof__(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (strongSelf.delegate != nil) {
            [strongSelf.delegate inviteViewController:strongSelf didDissmissedWithInvitingUserID:cell.userIDLabel.text];
        }
    }];
}

@end
