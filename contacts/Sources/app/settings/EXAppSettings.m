//
//  EXAppSettings.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAppSettings.h"

#pragma mark - Keys
static NSString * const kRootSettingsKey_LoadPhotos = @"LoadPhotosKey";
static NSString * const kRootSettingsKey_UseMobileNetworks = @"UseMobileNetworksKey";
static NSString * const kRootSettingsKey_UseLocalNotifications = @"UseLocalNotificationsKey";
static NSString * const kRootSettingsKey_CoworkersGroupName = @"CoworkersGroupKey";
static NSString * const kRootSettingsKey_LastSyncDate = @"LastSyncDateKey";
static NSString * const kRootSettingsKey_ContactsDatabaseVersion = @"ContactsDatabaseVersionKey";

@implementation EXAppSettings

#pragma mark - Info
+ (NSString *)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
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
    return [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_LastSyncDate];
}

+ (void)setLastSyncDate:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:kRootSettingsKey_LastSyncDate];
    [self save];
}

+ (void)removeLastSyncDate
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRootSettingsKey_LastSyncDate];
}

+ (NSString *)contactsStorgaeVersion
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_ContactsDatabaseVersion];
}

+ (void)setContactsStorageVersion:(NSString *)version
{
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:kRootSettingsKey_ContactsDatabaseVersion];
}

+ (void)removeContactsStorageVersion
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRootSettingsKey_ContactsDatabaseVersion];
}

#pragma mark - Private
+ (void)save
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
