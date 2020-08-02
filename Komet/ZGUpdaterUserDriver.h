//
//  ZGUpdaterUserDriver.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
@import SparkleCore;
#pragma clang diagnostic pop

@interface ZGUpdaterUserDriver : NSObject <SPUUserDriver>

- (instancetype)init;

@property (nonatomic, readonly) BOOL canCheckForUpdates;

@end
