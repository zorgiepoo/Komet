//
//  ZGPreferencesWindowController.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

@protocol ZGUserDefaultsListener;

NS_ASSUME_NONNULL_BEGIN

@interface ZGPreferencesWindowController : NSWindowController

- (instancetype)initWithDelegate:(id<ZGUserDefaultsListener>)delegate;

@end

NS_ASSUME_NONNULL_END
