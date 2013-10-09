//
//  EXContactsSyncViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsSyncViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>

#import "EXAlert.h"
#import "EXAppSettings.h"
#import "EXContactsService.h"

@interface EXContactsSyncViewController ()

@property (strong, nonatomic) NSDateFormatter *lastSyncDateFormatter;

@end

@implementation EXContactsSyncViewController

#pragma mark - UI lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.lastSyncDateFormatter  = [[NSDateFormatter alloc] init];
    [self.lastSyncDateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

#pragma mark - UI actions
- (IBAction)removeAccount:(id)sender
{
    [EXContactsService removeAccount];
}

- (IBAction)changeAccount:(id)sender {
}

- (IBAction)syncContacts:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [EXContactsService
        coworkers:^(BOOL success, id data, NSError *error)
        {
            if (success) {
                for (EXContact *contact in data) {
                    [self.responseTextView insertText:contact.mail];
                    [self.responseTextView insertText:@"\n"];
                }
                [EXAppSettings setLastSyncDate:[NSDate date]];
                [hud hide:YES];
                [self updateUI];
            } else {
                [hud hide:YES];
                [EXAlert fail:error];
            }
        }
    ];
}

#pragma mark - UI helpers
/**
 * Updates all UI components.
 */
- (void)updateUI
{
    self.userNameLabel.text = [EXContactsService signedUserName];
    NSDate *lastSyncDate = [EXAppSettings lastSyncDate];
    NSString *lastSyncDateString =
            lastSyncDate != nil ? [self.lastSyncDateFormatter stringFromDate:lastSyncDate] : @"undefined";
    self.lastSyncDateLabel.text = lastSyncDateString;
}

@end
