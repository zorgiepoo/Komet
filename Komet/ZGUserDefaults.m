//
//  ZGUserDefaults.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGUserDefaults.h"
#import "ZGWindowStyle.h"

NSFont *ZGReadDefaultFont(NSUserDefaults *userDefaults, NSString *fontNameDefaultsKey, NSString *fontSizeDefaultsKey)
{
	NSString *fontName = [userDefaults stringForKey:fontNameDefaultsKey];
	CGFloat fontSize = [userDefaults doubleForKey:fontSizeDefaultsKey];
	
	NSFont *font;
	if (fontName.length == 0)
	{
		font = [NSFont userFixedPitchFontOfSize:fontSize];
	}
	else
	{
		NSFont *userFont = [NSFont fontWithName:fontName size:fontSize];
		if (userFont != nil)
		{
			font = userFont;
		}
		else
		{
			font = [NSFont userFixedPitchFontOfSize:fontSize];
		}
	}
	return font;
}

void ZGWriteDefaultFont(NSUserDefaults *userDefaults, NSFont *font, NSString *fontNameKey, NSString *fontPointSizeKey)
{
	[userDefaults setObject:font.fontName forKey:fontNameKey];
	[userDefaults setObject:@(font.pointSize) forKey:fontPointSizeKey];
}

void ZGRegisterDefaultFont(NSUserDefaults *userDefaults, NSString *fontNameKey, NSString *pointSizeKey)
{
	[userDefaults registerDefaults:@{fontNameKey : @"", pointSizeKey : @(0.0)}];
}

NSInteger ZGReadDefaultLineLimit(NSUserDefaults *userDefaults, NSString *defaultsKey)
{
	NSUInteger limitRead = (NSUInteger)[userDefaults integerForKey:defaultsKey];
	return (NSInteger)MIN(limitRead, 1000LU);
}

ZGWindowStyleDefaultTheme ZGReadDefaultWindowStyleTheme(NSUserDefaults *userDefaults, NSString *defaultsKey)
{
	ZGWindowStyleDefaultTheme defaultTheme = {0};
	id<NSObject> themeDefault = [userDefaults objectForKey:defaultsKey];
	if (themeDefault == nil || (![themeDefault isKindOfClass:[NSNumber class]] && ![themeDefault isKindOfClass:[NSString class]]))
	{
		defaultTheme.automatic = true;
	}
	else
	{
		NSUInteger themeValue;
		if ([themeDefault isKindOfClass:[NSNumber class]])
		{
			themeValue = [(NSNumber *)themeDefault unsignedIntegerValue];
		}
		else
		{
			themeValue = (NSUInteger)[(NSString *)themeDefault integerValue];
		}
		
		if (themeValue > ZGWindowStyleMaxTheme)
		{
			defaultTheme.automatic = true;
		}
		else
		{
			defaultTheme.theme = themeValue;
		}
	}
	
	return defaultTheme;
}

void ZGWriteDefaultStyleTheme(NSUserDefaults *userDefaults, NSString *defaultsKey, ZGWindowStyleDefaultTheme defaultTheme)
{
	if (defaultTheme.automatic)
	{
		[userDefaults removeObjectForKey:defaultsKey];
	}
	else
	{
		[userDefaults setObject:@(defaultTheme.theme) forKey:defaultsKey];
	}
}

NSTimeInterval ZGReadDefaultTimeoutInterval(NSUserDefaults *userDefaults, NSString *defaultsKey, NSTimeInterval maxTimeout)
{
	NSTimeInterval timeoutRead = [userDefaults doubleForKey:defaultsKey];
	NSTimeInterval minTimeout = 0.0;
	return MIN(MAX(minTimeout, timeoutRead), maxTimeout);
}

NSURL * _Nullable ZGReadDefaultURL(NSUserDefaults *userDefaults, NSString *defaultsKey)
{
	NSString *urlString = [userDefaults stringForKey:defaultsKey];
	if (urlString.length == 0)
	{
		return nil;
	}
	
	return [NSURL fileURLWithPath:urlString];
}
