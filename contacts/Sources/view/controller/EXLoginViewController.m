//
//  EXLoginViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXLoginViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <SHAlertViewBlocks/SHAlertViewBlocks.h>

#import "EXAlert.h"
#import "EXContactsService.h"
#import "EXMainStoryboard.h"

@interface EXLoginViewController () <UITextFieldDelegate>

@end

@implementation EXLoginViewController

#pragma mark - UI lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    PRECONDITION_TRUE(self.contactsStorage != nil);
    [super viewWillAppear:animated];

    self.userNameTextField.text = @"";
    self.userPasswordTextField.text = @"";
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

#pragma mark - UI actions
- (IBAction)signIn:(id)sender {
    [self hideKeyboard];
    
    if (![self.userNameTextField.text exist]) {
        [EXAlert textFiledIsEmpty:self.userNameTextField.placeholder];
        [self.userNameTextField becomeFirstResponder];
        return;
    } else if (![self.userPasswordTextField.text exist]) {
        [EXAlert textFiledIsEmpty:self.userPasswordTextField.placeholder];
        [self.userPasswordTextField becomeFirstResponder];
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [EXContactsService signInUser:self.userNameTextField.text password:self.userPasswordTextField.text
        completion:^(BOOL success, id data, NSError *error)
        {
            if (success) {
                [self performSegueWithIdentifier:
                        [EXMainStoryboard loginToContactsNavigationViewControllerSegueId] sender:sender];
            } else {
                [EXAlert showWithMessage:[error localizedDescription] errorLevel:EXAlertErrorLevel_Fail];
            }
            [hud hide:YES];
        }
    ];
}

#pragma mark - UITextFieldDelegate protocol
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userNameTextField) {
        [self.userPasswordTextField becomeFirstResponder];
    } else if (textField == self.userPasswordTextField) {
        [textField resignFirstResponder];
        [self signIn:textField];
    }
    return YES;
}

#pragma mark - Private
#pragma mark - UI helpers
- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

@end
