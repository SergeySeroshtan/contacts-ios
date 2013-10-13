//
//  EXAlert.h
//  hubs
//
//  Created by Sergey Seroshtan on 28.09.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    EXAlertErrorLevel_Info = 0,
    EXAlertErrorLevel_Warning,
    EXAlertErrorLevel_Error,
    EXAlertErrorLevel_Fail
} EXAlertErrorLevelType;

@interface EXAlert : NSObject

+ (void)textFiledIsEmpty:(NSString *)textFieldName;

+ (void)showWithMessage:(NSString *)message errorLevel:(EXAlertErrorLevelType)errorLevel;

@end
