//
//  EXAppSettings.m
//  contacts
//
//  Created by Sergey Seroshtan on 09.10.13.
//  Copyright (c) 2013 Sergey Seroshtan. All rights reserved.
//

#import "EXAppSettings.h"

#pragma mark - Location
static NSString * const kRootSettings_Path = @"Settings.bundle/Root.plist";

#pragma mark - Keys
static NSString * const kRootSettingsKey_LoadPhotos = @"LoadPhotosKey";
static NSString * const kRootSettingsKey_UseMobileNetworks = @"UseMobileNetworksKey";
static NSString * const kRootSettingsKey_UseLocalNotifications = @"UseLocalNotificationsKey";
static NSString * const kRootSettingsKey_CoworkersGroupName = @"CoworkersGroupKey";
static NSString * const kRootSettingsKey_LastSyncDate = @"LastSyncDateKey";
static NSString * const kRootSettingsKey_ContactsDatabaseVersion = @"ContactsDatabaseVersionKey";
static NSString * const kRootSettingsKey_SyncPeriodKey = @"SyncPeriodKey";

@implementation EXAppSettings

#pragma mark - Initialize
+ (void)initialize
{
    BOOL fullyInitialized =
            [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_LoadPhotos] &&
            [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_UseMobileNetworks] &&
            [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_UseLocalNotifications] &&
            [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_CoworkersGroupName] &&
            [[NSUserDefaults standardUserDefaults] objectForKey:kRootSettingsKey_SyncPeriodKey];

    if (!fullyInitialized)  {

        NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *settingsPropertyListPath = [mainBundlePath stringByAppendingPathComponent:kRootSettings_Path];

        NSDictionary *settingsPropertyList = [NSDictionary dictionaryWithContentsOfFile:settingsPropertyListPath];

        NSMutableArray *preferenceArray = [settingsPropertyList objectForKey:@"PreferenceSpecifiers"];
        NSMutableDictionary *registerableDictionary = [NSMutableDictionary dictionary];

        for (int i = 0; i < [preferenceArray count]; ++i)  {
            NSString *key = [[preferenceArray objectAtIndex:i] objectForKey:@"Key"];
            if (key)  {
                id value = [[preferenceArray objectAtIndex:i] objectForKey:@"DefaultValue"];
                [registerableDictionary setObject:value forKey:key];
            }
        }

        [[NSUserDefaults standardUserDefaults] registerDefaults:registerableDictionary]; 
        [[NSUserDefaults standardUserDefaults] synchronize]; 
    }
}

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

+ (NSUInteger)syncPeriod
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kRootSettingsKey_SyncPeriodKey];
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
