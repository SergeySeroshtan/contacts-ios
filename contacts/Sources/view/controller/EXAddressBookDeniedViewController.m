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
#import "EXContactsStorage.h"


#import "EXContactsStorageConsumer.h"

@interface EXAddressBookDeniedViewController ()

@property (strong, nonatomic) EXContactsStorage *contactsStorage;

@end

@implementation EXAddressBookDeniedViewController

#pragma mark - UI lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contactsStorage = [[EXContactsStorage alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.addressBookDeniedWarnLabel.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.contactsStorage isAccessible]) {
        [self processAddressBookAccessGranted];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Accessing Address Book";
        [self.contactsStorage requestAccessWithCompletion:^(BOOL success, NSError *error) {
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

#pragma mark - Segue handling
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

#pragma mark - Private
#pragma mark - UI
- (void)processAddressBookAccessGranted
{
    NSString *segueIdentifier= [EXContactsService isUserSignedIn] ?
            [EXMainStoryboard addressBookDeniedToContactsNavigationViewControllerSegueId] :
            [EXMainStoryboard addressBookDeniedToLoginViewControllerSegueId];

    [self performSegueWithIdentifier:segueIdentifier sender:self];
}

@end
