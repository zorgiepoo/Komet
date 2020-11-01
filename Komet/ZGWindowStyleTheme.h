//
//  ZGWindowStyleTheme.h
//  Komet
//
//  Created by Mayur Pawashe on 11/13/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Foundation;

typedef NS_CLOSED_ENUM(NSUInteger, ZGWindowStyleTheme)
{
	ZGWindowStyleThemePlain = 0,
	ZGWindowStyleThemeDark,
	ZGWindowStyleThemePapyrus,
	ZGWindowStyleThemeBlue,
	ZGWindowStyleThemeGreen,
	ZGWindowStyleThemeRed
};

typedef struct
{
	ZGWindowStyleTheme theme;
	bool automatic;
	uint8_t unused[7];
} ZGWindowStyleDefaultTheme;

#define ZGWindowStyleAutomaticTag (-1)
