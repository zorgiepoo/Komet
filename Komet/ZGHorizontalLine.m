//
//  ZGHorizontalLine.m
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGHorizontalLine.h"

@implementation ZGHorizontalLine

- (void)drawRect:(NSRect)dirtyRect {
	[self.borderColor set];
	NSRectFill(NSMakeRect(0, 1, NSWidth(dirtyRect), 1));
	[super drawRect:dirtyRect];
}

@end
