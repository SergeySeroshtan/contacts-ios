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
            cancelButtonTitle:[self okButtonTitle] otherButtonTitles:nil];
    [alert show];
}

+ (void)showWithMessage:(NSString *)message errorLevel:(EXAlertErrorLevelType)errorLevel
{
    NSString *title = [self infoAlertTitle];
    switch (errorLevel) {
        case EXAlertErrorLevel_Info:
            title = [self infoAlertTitle];
            break;
        case EXAlertErrorLevel_Warning:
            title = [self warningAlertTtile];
            break;
        case EXAlertErrorLevel_Error:
            title = [self errorAlertTitle];
            break;
        case EXAlertErrorLevel_Fail:
            title = [self failAlertTitle];
            break;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:[self okButtonTitle] otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Private
#pragma mark - Alert buttons titles
+ (NSString *)okButtonTitle
{
    return NSLocalizedString(@"Ok", @"'Ok' button title for alert view");
}

+ (NSString *)cancelButtonTitle
{
    return NSLocalizedString(@"Cancel", @"'Cancel' button title for alert view");
}

#pragma mark - Alert titles
+ (NSString *)infoAlertTitle
{
    return NSLocalizedString(@"Info", "Title for 'Info' alert view.");
}

+ (NSString *)warningAlertTtile
{
   return NSLocalizedString(@"Warning", "Title for 'Warning' alert view.");
}

+ (NSString *)errorAlertTitle
{
    return NSLocalizedString(@"Error", "Title for 'Error' alert view.");
}

+ (NSString *)failAlertTitle
{
    return NSLocalizedString(@"Fail", "Title for 'Fail' alert view.");
}


@end
