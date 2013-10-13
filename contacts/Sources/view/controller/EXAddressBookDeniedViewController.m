//
//  EXAddressBookDeniedViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 11.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAddressBookDeniedViewController.h"

#import <AddressBook/AddressBook.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "EXMainStoryboard.h"
#import "EXContactsService.h"

#import "EXAlert.h"


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
    if ([self isAddressBookAccessPermited]) {
        [self processAddressBookPermissionGranted];
    } else {
        [self requestAddressBookAccessPermission];
    }
}

#pragma mark - Private
#pragma mark - UI
- (void)processAddressBookPermissionGranted
{
    NSAssert([self isAddressBookAccessPermited], @"At this point address book access should be permited.");

    NSString *segueIdentifier= [EXContactsService isUserSignedIn] ?
            [EXMainStoryboard addressBookDeniedToContactsNavigationViewControllerSegueId] :
            [EXMainStoryboard addressBookDeniedToLoginViewControllerSegueId];

    [self performSegueWithIdentifier:segueIdentifier sender:self];
}

#pragma mark - Address book
- (BOOL)isAddressBookAccessPermited
{
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (void)requestAddressBookAccessPermission
{
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (error != NULL) {
        self.addressBookDeniedWarnLabel.hidden = NO;
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Accessing Address Book", @"Hud title | Accessing address book.");
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        [hud hide:YES];
        if (granted) {
            [self processAddressBookPermissionGranted];
        } else {
            self.addressBookDeniedWarnLabel.hidden = NO;
        }
    });
}

@end
