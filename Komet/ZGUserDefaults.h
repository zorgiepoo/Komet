//
//  ZGUserDefaults.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

#import "ZGWindowStyleTheme.h"

NS_ASSUME_NONNULL_BEGIN

void ZGRegisterDefaultFont(NSUserDefaults *userDefaults, NSString *fontNameKey, NSString *pointSizeKey);
NSFont *ZGReadDefaultFont(NSUserDefaults *userDefaults, NSString *fontNameDefaultsKey, NSString *fontSizeDefaultsKey);
void ZGWriteDefaultFont(NSUserDefaults *userDefaults, NSFont *font, NSString *fontNameKey, NSString *fontPointSizeKey);

NSInteger ZGReadDefaultLineLimit(NSUserDefaults *userDefaults, NSString *defaultsKey);

ZGWindowStyleDefaultTheme ZGReadDefaultWindowStyleTheme(NSUserDefaults *userDefaults, NSString *defaultsKey);
void ZGWriteDefaultStyleTheme(NSUserDefaults *userDefaults, NSString *defaultsKey, ZGWindowStyleDefaultTheme defaultTheme);

NSTimeInterval ZGReadDefaultTimeoutInterval(NSUserDefaults *userDefaults, NSString *defaultsKey, NSTimeInterval maxTimeout);

NSURL * _Nullable ZGReadDefaultURL(NSUserDefaults *userDefaults, NSString *defaultsKey);

NS_ASSUME_NONNULL_END
