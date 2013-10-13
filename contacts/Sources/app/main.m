//
//  main.m
//  contacts
//
//  Created by Sergey Seroshtan on 07.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EXAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        @try {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([EXAppDelegate class]));
        }
        @catch (NSException *exception) {
            NSLog(@"Application crashed due to exception: %@", exception);
            @throw exception;
        }
    }
}
