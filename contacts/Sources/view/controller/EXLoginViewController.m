//
//  EXLoginViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXLoginViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>

#import "EXAlert.h"
#import "EXContactsService.h"

static NSString * const kSignInToContactsSegueIdentifier = @"SignInToContactsSegueIdentifier";

@interface EXLoginViewController () <UITextFieldDelegate>

@end

@implementation EXLoginViewController

#pragma mark - UI lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([EXContactsService isUserSignedIn]) {
        [self performSegueWithIdentifier:kSignInToContactsSegueIdentifier sender:self];
    } else {
        self.userNameTextField.text = @"";
        self.userPasswordTextField.text = @"";
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
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [EXContactsService signInUser:self.userNameTextField.text password:self.userPasswordTextField.text
        completion:^(BOOL success, id data, NSError *error)
        {
            if (success) {
                [self performSegueWithIdentifier:kSignInToContactsSegueIdentifier sender:sender];
            } else {
                [EXAlert fail:error];
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
