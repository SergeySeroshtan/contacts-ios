//
//  EXContactsViewController.h
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EXContactsViewController : UIViewController

/// @name UI outlets
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastSyncDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *syncContactsButton;
@property (weak, nonatomic) IBOutlet UILabel *syncContactsStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *syncPhotosStatusLabel;

/// @name UI actions
- (IBAction)syncNow:(id)sender;
- (IBAction)editAccount:(id)sender;

@end
