//
//  EXAppSettings.h
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This class encapsulates access to the application settings.
 */
@interface EXAppSettings : NSObject

/// @name Info
+ (NSString *)appVersion;

/// @name Root settings
/// @name Network
+ (BOOL)loadPhotots;
+ (void)setLoadPhotos:(BOOL)enable;

+ (BOOL)useMobileNetworks;
+ (void)setUseMobileNetworks:(BOOL)enable;

/// @name Notifications
+ (BOOL)useLocalNotifications;
+ (void)setUseLocalNotifications:(BOOL)enable;

/// @name Address Book
+ (NSString *)coworkersGroupName;
+ (void)setCoworkersGroupName:(NSString *)groupName;

/// @name Utility settings
+ (NSDate *)lastSyncDate;
+ (void)setLastSyncDate:(NSDate *)date;
+ (void)removeLastSyncDate;

+ (NSString *)contactsDatabaseVersion;
+ (void)setContactsDatabaseVersion:(NSString *)version;
+ (void)removeContactsDatabaseVersion;

@end
