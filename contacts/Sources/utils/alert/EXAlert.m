//
//  EXAlert.m
//  hubs
//
//  Created by Sergey Seroshtan on 28.09.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAlert.h"

@implementation EXAlert

+ (void)textFiledIsEmpty:(NSString *)textFieldName
{
    NSString *title = [NSString stringWithFormat:@"Field '%@' is empty", textFieldName];
    NSString *message = [NSString stringWithFormat:@"Please put correct value to the filed '%@'", textFieldName];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

+ (void)userNameOrPasswordIsInvalid
{
    NSString *title = @"Error";
    NSString *message = @"User name or password is invalid";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
@end
