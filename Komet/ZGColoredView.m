//
//  ZGColoredView
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGColoredView.h"

@implementation ZGColoredView

- (void)drawRect:(NSRect)dirtyRect {
	[self.backgroundColor set];
	NSRectFill(dirtyRect);
	
	[super drawRect:dirtyRect];
}

@end
