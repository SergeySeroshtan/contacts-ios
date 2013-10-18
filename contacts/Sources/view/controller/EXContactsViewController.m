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

#import "EXContactsStorage.h"

#import "EXAlert.h"
#import "EXContactsService.h"
#import "EXMainStoryboard.h"

#define CF_SAFE_RELEASE(x)\
        if (x) {\
            CFRelease(x);\
            x = NULL;\
        }

@interface EXContactsViewController () <UIActionSheetDelegate>

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
}

- (void)viewWillAppear:(BOOL)animated
{
    PRECONDITION_TRUE(self.contactsStorage != nil);
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id<EXContactsStorageConsumer> contactsStorageConsumer = nil;
    if ([segue.destinationViewController conformsToProtocol:@protocol(EXContactsStorageConsumer)]) {
        contactsStorageConsumer = segue.destinationViewController;
    } else {
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
            UIViewController *visibleViewController = [navigationController.viewControllers lastObject];
            if ([visibleViewController conformsToProtocol:@protocol(EXContactsStorageConsumer)]) {
                contactsStorageConsumer = (id<EXContactsStorageConsumer>)visibleViewController;
            }
        }
    }
    if (contactsStorageConsumer) {
        [contactsStorageConsumer setContactsStorage:self.contactsStorage];
    } else {
        NSLog(@"Warning: Destination view controller does not implement %@ protocol!",
                NSStringFromProtocol(@protocol(EXContactsStorageConsumer)));
    }
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
                [self.contactsStorage drop];
                [EXContactsService signOut];
                [self performSegueWithIdentifier:[EXMainStoryboard contactsToLoginViewControllerSegueId]
                        sender:self.view];
            }
        }];
    [confirmation show];
}

- (IBAction)changeAccount:(id)sender {
    NSString *cancelButtonTitle = @"Cancel";
    NSString *removeAccountButtonTitle = @"Remove account";

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
    hud.labelText = @"Sync contacts";
    [EXContactsService
        coworkers:^(BOOL success, id data, NSError *error)
        {
            if (success) {
                if ([self.contactsStorage syncContacts:data]) {
                    [self updateUI];
                } else {
                    NSLog(@"Sync contacts failed due to error %@", self.contactsStorage.error);
                }
                [hud hide:YES];
            } else {
                [hud hide:YES];
                [EXAlert showWithMessage:[error localizedDescription] errorLevel:EXAlertErrorLevel_Fail];
            }
        }
    ];
}

#pragma mark - Private
#pragma mark - UI helpers
/**
 * Updates all UI components.
 */
- (void)updateUI
{
    self.userNameLabel.text = [EXContactsService signedUserName];
    NSDate *lastSyncDate = [self.contactsStorage lastSyncDate];
    self.lastSyncDateLabel.text = lastSyncDate != nil ?
            [NSString stringWithFormat:@"Last sync: %@", [self.lastSyncDateFormatter stringFromDate:lastSyncDate]] :
            @"Contacts is not synced yet";
}

@end
