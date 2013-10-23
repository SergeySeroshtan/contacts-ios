//
//  EXAppDelegate.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAppDelegate.h"

#import "EXAppSettings.h"
#import "EXMainStoryboard.h"
#import "EXContactsSyncer.h"

@interface EXAppDelegate ()

@end

@implementation EXAppDelegate


#pragma mark - Application lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureContactsSyncer];
    EXContactsSyncer *contactsSyncer = [EXContactsSyncer sharedInstance];
    if (contactsSyncer.isAccessible) {
        if (contactsSyncer.isUserSignedIn && contactsSyncer.signedUserContact == nil) {
            // Application was removed without 'Remove Account' action.
            // So shoud previos account should be removed.
            [contactsSyncer removeAccount];
        }
    }
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self configureContactsSyncer];
    self.window.rootViewController = [self.window.rootViewController.storyboard
            instantiateViewControllerWithIdentifier:[EXMainStoryboard addressBookDeniedViewControllerId]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    EXContactsSyncer *contactsSyncer = [EXContactsSyncer sharedInstance];
    if (contactsSyncer.isAccessible && contactsSyncer.isUserSignedIn) {
        [contactsSyncer awake];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EXContactsSyncer sharedInstance] sleep];
}

- (void)configureContactsSyncer
{
    EXContactsSyncer *contactsSyncer = [EXContactsSyncer sharedInstance];
    contactsSyncer.loadPhotos = [EXAppSettings loadPhotots];
    contactsSyncer.useMobileNetworks = [EXAppSettings useMobileNetworks];
    contactsSyncer.localNotificationEnabled = [EXAppSettings useLocalNotifications];
    contactsSyncer.groupName = [EXAppSettings coworkersGroupName];
    contactsSyncer.syncPeriod = [EXAppSettings syncPeriod];
}


@end
