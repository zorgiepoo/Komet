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

@end
