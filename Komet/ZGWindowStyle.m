//
//  ZGWindowStyle.m
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGWindowStyle.h"

@implementation ZGWindowStyle

- (instancetype)initWithBarColor:(NSColor *)barColor barTextColor:(NSColor *)barTextColor dividerLineColor:(NSColor *)dividerLineColor material:(NSVisualEffectMaterial)material textColor:(NSColor *)textColor textHighlightColor:(NSColor * _Nullable)textHighlightColor commentColor:(NSColor *)commentColor overflowColor:(NSColor *)overflowColor fallbackBackgroundColor:(NSColor *)fallbackBackgroundColor scrollerKnobStyle:(NSScrollerKnobStyle)scrollerKnobStyle
{
	self = [super init];
	if (self != nil)
	{
		_barColor = barColor;
		_barTextColor = barTextColor;
		_dividerLineColor = dividerLineColor;
		_material = material;
		_textColor = textColor;
		_textHighlightColor = textHighlightColor;
		_commentColor = commentColor;
		_overflowColor = overflowColor;
		_fallbackBackgroundColor = fallbackBackgroundColor;
		_scrollerKnobStyle = scrollerKnobStyle;
	}
	return self;
}

+ (ZGWindowStyle *)windowStyleWithTheme:(ZGWindowStyleTheme)theme
{
	switch (theme)
	{
		case ZGWindowStyleThemeDefault:
			return
			[[ZGWindowStyle alloc]
			 initWithBarColor:[NSColor colorWithDeviceWhite:0.9 alpha:1.0]
			 barTextColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			 dividerLineColor:[NSColor colorWithDeviceRed:205 / 255.0 green:205 / 255.0 blue:205 / 255.0 alpha:1.0]
			 material:NSVisualEffectMaterialLight
			 textColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			 textHighlightColor:nil
			 commentColor:[NSColor darkGrayColor]
			 overflowColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.0 alpha:0.3]
			 fallbackBackgroundColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.95]
			 scrollerKnobStyle:NSScrollerKnobStyleDark];
		case ZGWindowStyleThemeDark:
		{
			NSVisualEffectMaterial material = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 11, 0}] ? NSVisualEffectMaterialUltraDark : NSVisualEffectMaterialDark;
			
			return
			[[ZGWindowStyle alloc]
			 initWithBarColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			 barTextColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]
			 dividerLineColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			 material:material
			 textColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]
			 textHighlightColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.4]
			 commentColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.7]
			 overflowColor:[NSColor colorWithDeviceRed:1 green:0.690 blue:0.231 alpha:0.3]
			 fallbackBackgroundColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.9]
			 scrollerKnobStyle:NSScrollerKnobStyleLight];
		}
		case ZGWindowStyleThemePapyrus:
			return
			[[ZGWindowStyle alloc]
			 initWithBarColor:[NSColor colorWithDeviceRed:1 green:0.941 blue:0.647 alpha:0.95]
			 barTextColor:[NSColor colorWithDeviceRed:0.714 green:0.286 blue:0.149 alpha:1]
			 dividerLineColor:[NSColor colorWithDeviceRed:188 / 255.0 green:169 / 255.0 blue:57 / 255.0 alpha:0.55]
			 material:NSVisualEffectMaterialLight
			 textColor:[NSColor colorWithDeviceRed:0.557 green:0.157 blue:0 alpha:1]
			 textHighlightColor:nil
			 commentColor:[NSColor colorWithDeviceRed:0.714 green:0.286 blue:0.149 alpha:1]
			 overflowColor:[NSColor colorWithDeviceRed:1 green:0.690 blue:0.231 alpha:0.5]
			 fallbackBackgroundColor:[NSColor colorWithDeviceRed:1 green:0.941 blue:0.647 alpha:0.9]
			 scrollerKnobStyle:NSScrollerKnobStyleDark];
		case ZGWindowStyleThemeBlue:
		{
			NSColor *barAndTextHighlightColor = [NSColor colorWithDeviceRed:0.204 green:0.596 blue:0.859 alpha:1];
			return
			[[ZGWindowStyle alloc]
			 initWithBarColor:barAndTextHighlightColor
			 barTextColor:[NSColor colorWithDeviceRed:0.925 green:0.941 blue:0.945 alpha:1]
			 dividerLineColor:barAndTextHighlightColor
			 material:NSVisualEffectMaterialLight
			 textColor:[NSColor colorWithDeviceRed:0.173 green:0.243 blue:0.314 alpha:1]
			 textHighlightColor:barAndTextHighlightColor
			 commentColor:[NSColor colorWithDeviceRed:0.161 green:0.502 blue:0.725 alpha:1]
			 overflowColor:[NSColor colorWithDeviceRed:0.831 green:0.753 blue:0.169 alpha:0.3]
			 fallbackBackgroundColor:[NSColor colorWithDeviceRed:0.925 green:0.941 blue:0.945 alpha:0.9]
			 scrollerKnobStyle:NSScrollerKnobStyleDark];
		}
		case ZGWindowStyleThemeGreen:
		{
			NSVisualEffectMaterial material = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 11, 0}] ? NSVisualEffectMaterialMediumLight : NSVisualEffectMaterialLight;
			
			NSColor *barAndTextHighlightColor = [NSColor colorWithDeviceRed:0.361 green:0.514 blue:0.184 alpha:1];
			return
			[[ZGWindowStyle alloc]
			 initWithBarColor:barAndTextHighlightColor
			 barTextColor:[NSColor colorWithDeviceRed:0.847 green:0.792 blue:0.659 alpha:1]
			 dividerLineColor:barAndTextHighlightColor
			 material:material
			 textColor:[NSColor colorWithDeviceRed:0.157 green:0.286 blue:0.027 alpha:1]
			 textHighlightColor:barAndTextHighlightColor
			 commentColor:[NSColor colorWithDeviceRed:0.361 green:0.514 blue:0.184 alpha:1]
			 overflowColor:[NSColor colorWithDeviceRed:0.831 green:0.753 blue:0.169 alpha:0.5]
			 fallbackBackgroundColor:[NSColor colorWithDeviceRed:0.847 green:0.792 blue:0.659 alpha:0.9]
			 scrollerKnobStyle:NSScrollerKnobStyleDark];
		}
		case ZGWindowStyleThemeRed:
		{
			NSVisualEffectMaterial material = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 11, 0}] ? NSVisualEffectMaterialUltraDark : NSVisualEffectMaterialDark;
			
			NSColor *barAndTextHighlightColor = [NSColor colorWithDeviceRed:0.863 green:0.208 blue:0.133 alpha:1];
			return
			[[ZGWindowStyle alloc]
			 initWithBarColor:barAndTextHighlightColor
			 barTextColor:[NSColor colorWithDeviceRed:0.118 green:0.118 blue:0.125 alpha:1]
			 dividerLineColor:barAndTextHighlightColor
			 material:material
			 textColor:[NSColor colorWithDeviceRed:0.963 green:0.308 blue:0.233 alpha:1]
			 textHighlightColor:barAndTextHighlightColor
			 commentColor:[NSColor colorWithDeviceRed:0.863 green:0.208 blue:0.133 alpha:1]
			 overflowColor:[NSColor colorWithDeviceRed:1 green:0.690 blue:0.231 alpha:0.3]
			 fallbackBackgroundColor:[NSColor colorWithDeviceRed:0.165 green:0.173 blue:0.169 alpha:0.95]
			 scrollerKnobStyle:NSScrollerKnobStyleLight];
		}
	}
}

@end
