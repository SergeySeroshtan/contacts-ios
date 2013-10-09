//
//  EXAppSettings.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAppSettings.h"

#pragma mark - Date format
NSString * const kDateFromat_LastSync = @"dd/MM/yyyy hh:mm:ss";

#pragma mark - Keys
static NSString * const kRootSettingsKey_LoadPhotos = @"LoadPhotosKey";
static NSString * const kRootSettingsKey_UseMobileNetworks = @"UseMobileNetworksKey";
static NSString * const kRootSettingsKey_UseLocalNotifications = @"UseLocalNotificationsKey";
static NSString * const kRootSettingsKey_CoworkersGroupName = @"CoworkersGroupKey";
static NSString * const kRootSettingsKey_LastSyncDate = @"LastSyncDateKey";

@implementation EXAppSettings

// Date formatter for lastSyncDate setting
static NSDateFormatter *lastSyncDateFormatter = nil;

#pragma mark - Initialize
+ (void)initialize
{
    lastSyncDateFormatter = [[NSDateFormatter alloc] init];
    [lastSyncDateFormatter setDateFormat:kDateFromat_LastSync];
}

#pragma mark - Network
+ (BOOL)loadPhotots
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRootSettingsKey_LoadPhotos];
}

+ (void)setLoadPhotos:(BOOL)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:kRootSettingsKey_LoadPhotos];
    [self save];
}

+ (BOOL)useMobileNetworks
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRootSettingsKey_UseMobileNetworks];
}

+ (void)setUseMobileNetworks:(BOOL)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:kRootSettingsKey_UseMobileNetworks];
    [self save];
}

#pragma mark - Notifications
+ (BOOL)useLocalNotifications
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRootSettingsKey_UseLocalNotifications];
}

+ (void)setUseLocalNotifications:(BOOL)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:kRootSettingsKey_UseLocalNotifications];
    [self save];
}

#pragma mark - Address Book
+ (NSString *)coworkersGroupName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_CoworkersGroupName];
}

+ (void)setCoworkersGroupName:(NSString *)groupName
{
    [[NSUserDefaults standardUserDefaults] setObject:groupName forKey:kRootSettingsKey_CoworkersGroupName];
    [self save];
}

#pragma mark - Info
+ (NSDate *)lastSyncDate
{
    NSString *dateString = [[NSUserDefaults standardUserDefaults] stringForKey:kRootSettingsKey_LastSyncDate];
    return [lastSyncDateFormatter dateFromString:dateString];
}

+ (void)setLastSyncDate:(NSDate *)date
{
    NSString *dateString = [lastSyncDateFormatter stringFromDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:dateString forKey:kRootSettingsKey_LastSyncDate];
    [self save];
}

#pragma mark - Private
+ (void)save
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
