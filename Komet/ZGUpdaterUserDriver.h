//
//  ZGUpdaterUserDriver.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;
@import SparkleCore;

@interface ZGUpdaterUserDriver : NSObject <SPUUserDriver>

- (instancetype)init;

@property (nonatomic, readonly) BOOL canCheckForUpdates;

@end
