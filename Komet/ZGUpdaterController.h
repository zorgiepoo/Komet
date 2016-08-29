//
//  ZGUpdaterController.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Foundation;
@import SparkleCore;

#import "ZGUpdaterSettingsListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGUpdaterController : NSObject <SPUUpdaterDelegate, ZGUpdaterSettingsListener>

- (instancetype)init;

@property (nonatomic, readonly) BOOL canCheckForUpdates;

- (BOOL)canCheckForUpdates;
- (void)checkForUpdates;

@end

NS_ASSUME_NONNULL_END
