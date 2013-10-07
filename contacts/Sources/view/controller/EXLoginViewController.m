//
//  EXLoginViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXLoginViewController.h"

#import "EXAlert.h"

static NSString * const kSignInToContactsSegueIdentifier = @"SignInToContactsSegueIdentifier";

@interface EXLoginViewController () <UITextFieldDelegate>

@end

@implementation EXLoginViewController

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
    
    [self performSegueWithIdentifier:kSignInToContactsSegueIdentifier sender:sender];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

@end
