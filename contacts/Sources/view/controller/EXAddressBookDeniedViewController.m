//
//  EXAddressBookDeniedViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 11.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAddressBookDeniedViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>

#import "EXMainStoryboard.h"
#import "EXContactsService.h"

#import "EXAlert.h"
#import "EXContactsSyncer.h"


@interface EXAddressBookDeniedViewController ()

@end

@implementation EXAddressBookDeniedViewController

#pragma mark - UI lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.addressBookDeniedWarnLabel.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([[EXContactsSyncer sharedInstance] isAddressBookAccessPermitted]) {
        [self processAddressBookAccessGranted];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Accessing Address Book";
        [[EXContactsSyncer sharedInstance] requestAddressBookAccessPermissions:^(BOOL success, NSError *error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [hud hide:YES];
                if (success) {
                    [self processAddressBookAccessGranted];
                } else {
                    self.addressBookDeniedWarnLabel.hidden = NO;
                }
            });
        }];
    }
}

#pragma mark - Private
#pragma mark - UI
- (void)processAddressBookAccessGranted
{
    NSString *segueIdentifier= [[EXContactsSyncer sharedInstance] isUserSignedIn] ?
            [EXMainStoryboard addressBookDeniedToContactsNavigationViewControllerSegueId] :
            [EXMainStoryboard addressBookDeniedToLoginViewControllerSegueId];

    [self performSegueWithIdentifier:segueIdentifier sender:self];
}

@end
