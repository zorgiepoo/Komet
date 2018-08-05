//
//  ZGCommitTextView.h
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@protocol ZGCommitViewDelegate <NSTextViewDelegate, NSTouchBarDelegate>

- (void)zgCommitViewSelectAll;
- (void)zgCommitViewTouchCommit:(id)sender;
- (void)zgCommitViewTouchCancel:(id)sender;

@end

@interface ZGCommitTextView : NSTextView

- (void)zgLoadDefaults;
- (void)zgDisableContinuousSpellingAndAutomaticSpellingCorrection;

// Not using a weak reference because I'm not sure it's safe for NSTextView to be using
@property (nonatomic, assign, nullable) id<ZGCommitViewDelegate> zgCommitViewDelegate;

@end

NS_ASSUME_NONNULL_END
