//
//  EXContactsStorageConsumer.h
//  contacts
//
//  Created by Sergey Seroshtan on 17.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EXContactsStorage;

@protocol EXContactsStorageConsumer <NSObject>

@required
- (void)setContactsStorage:(EXContactsStorage *)contactsStorage;

@end
