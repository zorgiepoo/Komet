//
//  ZGWindowStyle.h
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import AppKit;

@interface ZGWindowStyle : NSObject

@property (nonatomic, nonnull) NSColor* barColor;
@property (nonatomic, nonnull) NSColor* barTextColor;
@property (nonatomic, nonnull) NSColor* backgroundColor;
@property (nonatomic, nonnull) NSColor* textColor;
@property (nonatomic, nonnull) NSColor* commentColor;
@property (nonatomic, nonnull) NSColor* overflowColor;

+ (ZGWindowStyle * _Nonnull)withBar: (NSColor * _Nonnull)barColor barText:(NSColor * _Nonnull)barTextColor background: (NSColor * _Nonnull)backgroundColor text: (NSColor * _Nonnull)textColor comment: (NSColor * _Nonnull)commentColor overflow: (NSColor * _Nonnull)overflowColor;

@end
