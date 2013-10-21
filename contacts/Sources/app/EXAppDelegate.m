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
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    EXContactsSyncer *contactsSyncer = [EXContactsSyncer sharedInstance];
    contactsSyncer.photosLoadingEnabled = [EXAppSettings loadPhotots];
    contactsSyncer.mobileNetworksEnabled = [EXAppSettings useMobileNetworks];
    contactsSyncer.localNotificationEnabled = [EXAppSettings useLocalNotifications];
    contactsSyncer.groupName = [EXAppSettings coworkersGroupName];

    if (contactsSyncer.isAccessible) {
        [contactsSyncer awake];
    }
    
    self.window.rootViewController = [self.window.rootViewController.storyboard
            instantiateViewControllerWithIdentifier:[EXMainStoryboard addressBookDeniedViewControllerId]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EXContactsSyncer sharedInstance] sleep];
}


@end
