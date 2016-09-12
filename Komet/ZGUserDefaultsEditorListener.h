//
//  ZGUserDefaultsEditorListener.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol ZGUserDefaultsEditorListener <NSObject>

- (void)userDefaultsChangedMessageFont;

- (void)userDefaultsChangedCommentsFont;

- (void)userDefaultsChangedRecommendedLineLengthLimits;

- (void)userDefaultsChangedWindowStyle;

- (void)userDefaultsChangedWindowVibrancy;

@end

NS_ASSUME_NONNULL_END
