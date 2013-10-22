//
//  EXContactsViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsViewController.h"

#import <AddressBook/AddressBook.h>

#import <MBProgressHUD/MBProgressHUD.h>
#import <SHActionSheetBlocks/SHActionSheetBlocks.h>
#import <SHAlertViewBlocks/SHAlertViewBlocks.h>
#import <AFNetworking/AFNetworking.h>

#import "EXAlert.h"
#import "EXMainStoryboard.h"

#import "EXContact.h"
#import "EXContactsSyncer.h"

#pragma mark - Sync status labels
static NSString * const kSyncStatusLabel_Undefined = @"undefined";
static NSString * const kSyncStatusLabel_Started = @"started";
static NSString * const kSyncStatusLabel_Stopped = @"stopped";

@interface EXContactsViewController () <EXContactSyncObserver>

@property (strong, nonatomic) NSDateFormatter *lastSyncDateFormatter;

@end

@implementation EXContactsViewController

#pragma mark - Initialization
- (void)makeInitialization
{
    self.lastSyncDateFormatter  = [[NSDateFormatter alloc] init];
    [self.lastSyncDateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss"];
}

#pragma mark - UI lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self makeInitialization];
    [[EXContactsSyncer sharedInstance] addSyncObserver:self];
    [self updateUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    PRECONDITION_TRUE([[EXContactsSyncer sharedInstance] isAccessible]);
    [super viewWillAppear:animated];
    [self updateSyncLabels];
}

#pragma mark - UI actions
- (void)removeAccount
{
    NSString *cancelButtonTitle = @"Cancel";
    NSString *confirmationTitle = @"Attention";
    NSString *removeAccountButtonTitle = @"Remove";
    NSString *confirmationMessage = @"Removing account will also remove all related contacts from your address book!";

    UIAlertView *confirmation = [UIAlertView SH_alertViewWithTitle:confirmationTitle
        andMessage:confirmationMessage buttonTitles:@[removeAccountButtonTitle]
        cancelTitle:cancelButtonTitle withBlock:^(NSInteger buttonIndex) {
            const NSInteger removeAccountButtonIndex = 1;
            if (buttonIndex == removeAccountButtonIndex) {
                [[EXContactsSyncer sharedInstance] removeAccount];
                [self performSegueWithIdentifier:[EXMainStoryboard contactsToLoginViewControllerSegueId]
                        sender:self.view];
            }
        }];
    [confirmation show];
}

- (void)forcePhotosSync
{
    [[EXContactsSyncer sharedInstance] resyncPhotos];
}

- (IBAction)editAccount:(id)sender {
    NSString *cancelButtonTitle = @"Cancel";
    NSString *removeAccountButtonTitle = @"Remove account";
    NSString *forcePhotosSyncButtonTitle = @"Force photos sync";

    UIActionSheet *changeAccountSheet = [UIActionSheet SH_actionSheetWithTitle:nil
            buttonTitles:@[forcePhotosSyncButtonTitle] cancelTitle:cancelButtonTitle
            destructiveTitle:removeAccountButtonTitle
        withBlock:^(NSInteger buttonIndex)
        {
            const NSInteger removeAccountButtonIndex = 0;
            const NSInteger forcePhotosUpdatingButtonIndex = 1;
            if (buttonIndex == removeAccountButtonIndex) {
                [self removeAccount];
            } else if (buttonIndex == forcePhotosUpdatingButtonIndex) {
                [self forcePhotosSync];
            }
        }
    ];
    [changeAccountSheet showInView:self.view];
}

- (IBAction)syncNow:(id)sender {
    [[EXContactsSyncer sharedInstance] syncNow];
}

#pragma mark - EXContactsSyncObserver
- (void)contactsSyncerDidStartContactsSync:(EXContactsSyncer *)contactsSyncer
{
    self.syncContactsStatusLabel.text = kSyncStatusLabel_Started;
}

- (void)contactsSyncerDidFinishContactsSync:(EXContactsSyncer *)contactsSyncer
{
    self.syncContactsStatusLabel.text = kSyncStatusLabel_Stopped;
    [self updateSyncLabels];
}

- (void)contactsSyncerDidFailContactsSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error
{
    self.syncContactsStatusLabel.text = kSyncStatusLabel_Stopped;
}

- (void)contactsSyncer:(EXContactsSyncer *)contactsSyncer didStartPhotosSync:(NSUInteger)photosCount
{
    self.syncPhotosStatusLabel.text = [NSString stringWithFormat:@"(0 / %lu)", (unsigned long)photosCount];
}

- (void)contactsSyncer:(EXContactsSyncer *)contactsSyncer didSyncPhotos:(NSUInteger)syncedPhotosCount
        ofTotal:(NSUInteger)totalPhotosCount
{
    self.syncPhotosStatusLabel.text = [NSString stringWithFormat:@"(%lu / %lu)",
            (unsigned long)syncedPhotosCount, (unsigned long)totalPhotosCount];
}

- (void)contactsSyncerDidFinishPhotosSync:(EXContactsSyncer *)contactsSyncer
{
    self.syncPhotosStatusLabel.text = kSyncStatusLabel_Stopped;
}

- (void)contactsSyncerDidFailPhotosSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error
{
    self.syncPhotosStatusLabel.text = kSyncStatusLabel_Stopped;
}

#pragma mark - Private
#pragma mark - UI helpers
/**
 * Updates all UI components.
 */
- (void)updateUI
{
    EXContact *myContact = [[EXContactsSyncer sharedInstance] signedUserContact];
    NSString *fullName = myContact != nil ?
            [NSString stringWithFormat:@"%@ %@", myContact.firstName, myContact.lastName] : @"";
    self.userNameLabel.text = fullName;
    [self updateSyncLabels];
}


- (void)updateSyncLabels
{
    NSDate *lastSyncDate = [[EXContactsSyncer sharedInstance] lastSyncDate];
    self.lastSyncDateLabel.text = lastSyncDate != nil ?
            [NSString stringWithFormat:@"%@", [self.lastSyncDateFormatter stringFromDate:lastSyncDate]] :
            kSyncStatusLabel_Undefined;

    self.syncContactsStatusLabel.text =
            [[EXContactsSyncer sharedInstance] isSyncContacts] ? kSyncStatusLabel_Started : kSyncStatusLabel_Stopped;
    self.syncPhotosStatusLabel.text =
            [[EXContactsSyncer sharedInstance] isSyncPhotos] ? kSyncStatusLabel_Started : kSyncStatusLabel_Stopped;

}

@end
