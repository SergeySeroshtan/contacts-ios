//
//  EXLoginViewController.h
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EXLoginViewController : UIViewController

/// @name UI outlets
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *userPasswordTextField;

/// @name UI actions
- (IBAction)signIn:(id)sender;
- (IBAction)showPassword:(id)sender;
@end
