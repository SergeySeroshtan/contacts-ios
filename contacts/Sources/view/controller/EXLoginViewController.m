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
#import "EXContactsSyncer.h"
#import "EXMainStoryboard.h"

@interface EXLoginViewController () <UITextFieldDelegate>

@end

@implementation EXLoginViewController

#pragma mark - UI lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.userNameTextField.text = @"";
    self.userPasswordTextField.text = @"";
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
    [[EXContactsSyncer sharedInstance] createAccount:self.userNameTextField.text
            password:self.userPasswordTextField.text
        completion:^(BOOL success, NSError *error)
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
