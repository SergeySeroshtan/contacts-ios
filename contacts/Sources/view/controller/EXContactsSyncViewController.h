//
//  EXContactsSyncViewController.h
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EXContactsSyncViewController : UIViewController

/// @name UI outlets
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastSyncDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *syncContactsButton;
@property (weak, nonatomic) IBOutlet UITextView *responseTextView;

/// @name UI actions
- (IBAction)syncContacts:(id)sender;

@end
