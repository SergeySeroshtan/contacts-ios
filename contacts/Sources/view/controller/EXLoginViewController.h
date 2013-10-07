//
//  EXLoginViewController.h
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EXLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *userPasswordTextField;

- (IBAction)signIn:(id)sender;
@end
