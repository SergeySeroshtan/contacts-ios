//
//  EXContactsSyncViewController.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXContactsSyncViewController.h"

#import "EXContactsService.h"

@interface EXContactsSyncViewController ()

@end

@implementation EXContactsSyncViewController

#pragma mark - UI lifecycle
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

@end
