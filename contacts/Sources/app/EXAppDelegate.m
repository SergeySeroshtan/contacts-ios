//
//  EXAppDelegate.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAppDelegate.h"

#import "EXContactsService.h"
#import "EXMainStoryboard.h"

@implementation EXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.window.rootViewController = [EXContactsService isUserSignedIn] ?
            [storyboard instantiateViewControllerWithIdentifier:[EXMainStoryboard contactsNavigationControllerId]] :
            [storyboard instantiateViewControllerWithIdentifier:[EXMainStoryboard loginViewControllerId]];

    [self.window makeKeyAndVisible];
    return YES;
}

@end
