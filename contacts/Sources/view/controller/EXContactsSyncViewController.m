//
//  EXContactsSyncViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsSyncViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <SHActionSheetBlocks/UIActionSheet+SHActionSheetBlocks.h>
#import <SHAlertViewBlocks/UIAlertView+SHAlertViewBlocks.h>

#import "EXAlert.h"
#import "EXAppSettings.h"
#import "EXContactsService.h"
#import "EXMainStoryboard.h"

@interface EXContactsSyncViewController () <UIActionSheetDelegate>

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
- (void)removeAccount
{
    NSString *cancelButtonTitle =
            NSLocalizedString(@"Cancel", @"Remove account confirmation alert | Cancel button title.");

    NSString *confirmationTitle =
            NSLocalizedString(@"Attention", @"Remove account confirmation alert | Title");

    NSString *removeAccountButtonTitle =
            NSLocalizedString(@"Remove", @"Remove account confirmation alert | Remove account button title");

    NSString *confirmationMessage =
            NSLocalizedString(@"Removing account will also remove all contacts from your address book!",
                    @"Remove account confirmation alert | Message");

    UIAlertView *confirmation = [UIAlertView SH_alertViewWithTitle:confirmationTitle
        andMessage:confirmationMessage buttonTitles:@[removeAccountButtonTitle]
        cancelTitle:cancelButtonTitle withBlock:^(NSInteger buttonIndex) {
            const NSInteger removeAccountButtonIndex = 1;
            if (buttonIndex == removeAccountButtonIndex) {
                [EXContactsService removeAccount];
                [self performSegueWithIdentifier:[EXMainStoryboard contactsToLoginViewControllerSegueId]
                        sender:self.view];
            }
        }];
    [confirmation show];
}

- (IBAction)changeAccount:(id)sender {
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Edit view | Change sheet | Cancel button title.");
    NSString *removeAccountButtonTitle =
            NSLocalizedString(@"Remove account", @"Edit view | Change sheet | Remove account button title.");

    UIActionSheet *changeAccountSheet = [UIActionSheet SH_actionSheetWithTitle:nil buttonTitles:nil
        cancelTitle:cancelButtonTitle destructiveTitle:removeAccountButtonTitle
        withBlock:^(NSInteger buttonIndex)
        {
            const NSInteger removeAccountButtonIndex = 0;
            if (buttonIndex == removeAccountButtonIndex) {
                [self removeAccount];
            }
        }
    ];
    [changeAccountSheet showInView:self.view];
}

- (IBAction)syncContacts:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
