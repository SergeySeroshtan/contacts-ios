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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    EXContactsSyncer *contactsSyncer = [EXContactsSyncer sharedInstance];
    contactsSyncer.photosLoadingEnabled = [EXAppSettings loadPhotots];
    contactsSyncer.mobileNetworksEnabled = [EXAppSettings useMobileNetworks];
    contactsSyncer.localNotificationEnabled = [EXAppSettings useLocalNotifications];
    contactsSyncer.groupName = [EXAppSettings coworkersGroupName];
    contactsSyncer.syncPeriod = [EXAppSettings syncPeriod];

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


@end
