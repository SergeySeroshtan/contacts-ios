//
//  EXContactsSyncViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsSyncViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>

#import "EXContactsService.h"
#import "EXAlert.h"

@interface EXContactsSyncViewController ()

@end

@implementation EXContactsSyncViewController

#pragma mark - UI lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.userNameLabel.text = [EXContactsService signedUserName];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        // Back button ('Sign Out') was clicked
        [self signOut:self];
    }
    [super viewWillDisappear:animated];
}

#pragma mark - UI actions
- (IBAction)signOut:(id)sender
{
    [EXContactsService signOut];
}

- (IBAction)syncContacts:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [EXContactsService
        coworkers:^(BOOL success, id data, NSError *error)
        {
            if (success) {
                for (EXContact *contact in data) {
                    [self.responseTextView insertText:contact.mail];
                    [self.responseTextView insertText:@"\n"];
                }
                [hud hide:YES];
            } else {
                [hud hide:YES];
                [EXAlert fail:error];
            }
        }
    ];
}

@end
