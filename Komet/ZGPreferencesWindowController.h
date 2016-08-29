//
//  ZGPreferencesWindowController.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

@protocol ZGUserDefaultsEditorListener;
@protocol ZGUpdaterSettingsListener;

NS_ASSUME_NONNULL_BEGIN

@interface ZGPreferencesWindowController : NSWindowController

- (instancetype)initWithEditorListener:(id<ZGUserDefaultsEditorListener>)editorListener updaterListener:(id<ZGUpdaterSettingsListener>)updaterListener;

@end

NS_ASSUME_NONNULL_END
