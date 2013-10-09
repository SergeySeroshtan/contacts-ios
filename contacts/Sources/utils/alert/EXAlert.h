//
//  EXAlert.h
//  hubs
//
//  Created by Sergey Seroshtan on 28.09.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EXAlert : NSObject

+ (void)textFiledIsEmpty:(NSString *)textFieldName;

+ (void)error:(NSError *)error;

+ (void)fail:(NSError *)error;

@end
