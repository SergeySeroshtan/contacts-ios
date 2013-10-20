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

@interface EXContactsViewController () <EXContactSyncObserver>

@property (strong, nonatomic) NSDateFormatter *lastSyncDateFormatter;
@property (assign, nonatomic) BOOL syncInProgress;

@end

@implementation EXContactsViewController

#pragma mark - Initialization
- (void)makeInitialization
{
    self.lastSyncDateFormatter  = [[NSDateFormatter alloc] init];
    [self.lastSyncDateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss"];
    
    self.syncInProgress = NO;
}

#pragma mark - UI lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self makeInitialization];
    [[EXContactsSyncer sharedInstance] addSyncObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    PRECONDITION_TRUE([[EXContactsSyncer sharedInstance] isAccessible]);
    [super viewWillAppear:animated];
    [self updateUI];
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
    MBProgressHUD *syncHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    syncHud.labelText = @"Sync contacts";
}

- (void)contactsSyncerDidFinishContactsSync:(EXContactsSyncer *)contactsSyncer
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self updateUI];
}

- (void)contactsSyncerDidFailPhotosSync:(EXContactsSyncer *)contactsSyncer withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [EXAlert showWithMessage:[error localizedDescription] errorLevel:EXAlertErrorLevel_Fail];
}

- (void)contactsSyncer:(EXContactsSyncer *)contactsSyncer didStartPhotosSync:(NSUInteger)photosCount
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = [NSString stringWithFormat:@"Sync photos (0 / %u)", photosCount];
}

- (void)contactsSyncer:(EXContactsSyncer *)contactsSyncer didSyncPhotos:(NSUInteger)syncedPhotosCount
        ofTotal:(NSUInteger)totalPhotosCount
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.labelText = [NSString stringWithFormat:@"Sync photos (%u / %u)", syncedPhotosCount, totalPhotosCount];
}

- (void)contactsSyncerDidFinishPhotosSync:(EXContactsSyncer *)contactsSyncer
{
    NSLog(@"Is main thread %d", [NSThread isMainThread]);
    [MBProgressHUD hideHUDForView:self.view animated:YES];
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
    NSDate *lastSyncDate = [[EXContactsSyncer sharedInstance] lastSyncDate];
    self.lastSyncDateLabel.text = lastSyncDate != nil ?
            [NSString stringWithFormat:@"Last sync: %@", [self.lastSyncDateFormatter stringFromDate:lastSyncDate]] :
            @"Contacts is not synced yet";
}

@end
