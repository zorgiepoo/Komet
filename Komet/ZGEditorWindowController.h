//
//  ZGEditorWindowController.h
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

#import "ZGUserDefaultsEditorListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGEditorWindowController : NSWindowController <ZGUserDefaultsEditorListener>

- (instancetype)initWithFileURL:(NSURL *)fileURL tutorialMode:(BOOL)tutorialMode;

- (void)exitWithSuccess:(BOOL)success __attribute__((noreturn));

@end

NS_ASSUME_NONNULL_END
