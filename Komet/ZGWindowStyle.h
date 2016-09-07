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

@interface ZGWindowStyle : NSObject

@property (nonatomic, nonnull) NSColor* barColor;
@property (nonatomic, nonnull) NSColor* barTextColor;
@property (atomic) NSVisualEffectMaterial material;
@property (nonatomic, nonnull) NSColor* textColor;
@property (nonatomic, nonnull) NSColor* commentColor;
@property (nonatomic, nonnull) NSColor* overflowColor;
@property (nonatomic, nonnull) NSColor* fallbackBackgroundColor;

+ (ZGWindowStyle * _Nonnull)withBar: (NSColor * _Nonnull)barColor barText:(NSColor * _Nonnull)barTextColor material: (NSVisualEffectMaterial)material text: (NSColor * _Nonnull)textColor comment: (NSColor * _Nonnull)commentColor overflow: (NSColor * _Nonnull)overflowColor fallbackColor: (NSColor * _Nonnull)fallbackColor;
+ (ZGWindowStyle * _Nonnull)withName: (NSString * _Nonnull)styleName;

@end
