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
    NSString *titleTemplate = NSLocalizedString(@"Field '%@' is empty",
            @"Title for alert that notifies user about required empty text field.");
    NSString *title = [NSString stringWithFormat:titleTemplate, textFieldName];

    NSString *message = NSLocalizedString(@"Please put correct value to this filed.",
            @"Message for alert that notifies user about required empty text field.");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

+ (void)error:(NSError *)error
{
    NSString *title = NSLocalizedString(@"Error", "Title for 'Error' alert view.");
    NSString *message = [error localizedDescription];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

+ (void)fail:(NSError *)error
{
    NSString *title = NSLocalizedString(@"Fail", "Title for 'Fail' alert view.");
    NSString *message = [error localizedDescription];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
@end
