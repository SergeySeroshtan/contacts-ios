//
//  EXAppDelegate.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAppDelegate.h"

#import "EXMainStoryboard.h"

@implementation EXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    self.window.rootViewController = [self.window.rootViewController.storyboard
            instantiateViewControllerWithIdentifier:[EXMainStoryboard addressBookDeniedViewControllerId]];
}

@end
