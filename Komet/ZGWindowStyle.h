//
//  ZGWindowStyle.h
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import AppKit;

#define ZGWindowStyleDefault @"default"
#define ZGWindowStyleDark @"dark"
#define ZGWindowStylePapyrus @"papyrus"
#define ZGWindowStyleBlue @"blue"
#define ZGWindowStyleGreen @"green"
#define ZGWindowStyleRed @"red"

NS_ASSUME_NONNULL_BEGIN

@interface ZGWindowStyle : NSObject

@property (nonatomic, readonly) NSColor *barColor;
@property (nonatomic, readonly) NSColor *barTextColor;
@property (nonatomic, readonly) NSVisualEffectMaterial material;
@property (nonatomic, readonly) NSColor *textColor;
@property (nonatomic, readonly) NSColor *commentColor;
@property (nonatomic, readonly) NSColor *overflowColor;
@property (nonatomic, readonly) NSColor *fallbackBackgroundColor;
@property (nonatomic, readonly) NSScrollerKnobStyle scrollerKnobStyle;

+ (ZGWindowStyle *)windowStyleWithStyleName:(NSString *)styleName;

@end

NS_ASSUME_NONNULL_END
