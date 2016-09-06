//
//  ZGWindowStyle.m
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGWindowStyle.h"

@implementation ZGWindowStyle

@synthesize barColor, barTextColor, backgroundColor, textColor, commentColor, overflowColor;

+ (ZGWindowStyle * _Nonnull)withBar: (NSColor * _Nonnull)barColor barText: (NSColor * _Nonnull)barTextColor background: (NSColor * _Nonnull)backgroundColor text: (NSColor * _Nonnull)textColor comment: (NSColor * _Nonnull)commentColor overflow: (NSColor * _Nonnull)overflowColor {
	ZGWindowStyle *style = [[ZGWindowStyle alloc] init];
	[style setBarColor:barColor];
	[style setBarTextColor:barTextColor];
	[style setBackgroundColor:backgroundColor];
	[style setTextColor:textColor];
	[style setCommentColor:commentColor];
	[style setOverflowColor:overflowColor];
    
	return style;
}

+ (ZGWindowStyle *) withName:(NSString *)styleName {
	if ([styleName isEqualToString:ZGWindowStyleDark]) {
		return [ZGWindowStyle
			  withBar:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			  barText:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]
			  background:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.9]
			  text:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]
			  comment:[NSColor colorWithDeviceRed:0.063 green:0.357 blue:0.388 alpha:1]
			  overflow:[NSColor colorWithDeviceRed:1.0 green:0.8 blue:0.8 alpha:1.0]
		  ];
	} else if ([styleName isEqualToString:ZGWindowStylePapyrus]) {
		return [ZGWindowStyle
			  withBar:[NSColor colorWithDeviceRed:1 green:0.941 blue:0.647 alpha:1.0]
			  barText:[NSColor colorWithDeviceRed:0.275 green:0.537 blue:0.400 alpha:1]
			  background:[NSColor colorWithDeviceRed:1 green:0.941 blue:0.647 alpha:0.9]
			  text:[NSColor colorWithDeviceRed:0.557 green:0.157 blue:0 alpha:1]
			  comment:[NSColor colorWithDeviceRed:0.714 green:0.286 blue:0.149 alpha:1]
			  overflow:[NSColor colorWithDeviceRed:1 green:0.690 blue:0.231 alpha:1]
		  ];
	} else if ([styleName isEqualToString:ZGWindowStyleBlue]) {
		return [ZGWindowStyle
			  withBar:[NSColor colorWithDeviceRed:0.204 green:0.596 blue:0.859 alpha:1]
			  barText:[NSColor colorWithDeviceRed:0.925 green:0.941 blue:0.945 alpha:1]
			  background:[NSColor colorWithDeviceRed:0.925 green:0.941 blue:0.945 alpha:0.9]
			  text:[NSColor colorWithDeviceRed:0.173 green:0.243 blue:0.314 alpha:1]
			  comment:[NSColor colorWithDeviceRed:0.161 green:0.502 blue:0.725 alpha:1]
			  overflow:[NSColor colorWithDeviceRed:0.906 green:0.298 blue:0.235 alpha:1]
		  ];
	} else if ([styleName isEqualToString:ZGWindowStyleGreen]) {
		return [ZGWindowStyle
                withBar:[NSColor colorWithDeviceRed:0.361 green:0.514 blue:0.184 alpha:1]
                barText:[NSColor colorWithDeviceRed:0.847 green:0.792 blue:0.659 alpha:1]
                background:[NSColor colorWithDeviceRed:0.847 green:0.792 blue:0.659 alpha:0.9]
                text:[NSColor colorWithDeviceRed:0.157 green:0.286 blue:0.027 alpha:1]
                comment:[NSColor colorWithDeviceRed:0.361 green:0.514 blue:0.184 alpha:1]
                overflow:[NSColor colorWithDeviceRed:0.212 green:0.224 blue:0.259 alpha:0.5]
		  ];
	} else {
		// Default style
		return [ZGWindowStyle
			  withBar:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]
			  barText:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			  background:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.95]
			  text:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]
			  comment:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.8]
			  overflow:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.3]
		  ];
	}
}

@end
