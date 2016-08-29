//
//  ZGUpdaterSettingsListener.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol ZGUpdaterSettingsListener <NSObject>

- (void)updaterSettingsChangedAutomaticallyInstallingUpdates:(BOOL)automaticallyInstallUpdates;

@end

NS_ASSUME_NONNULL_END
