//
//  ZGEditorWindowController.h
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@interface ZGEditorWindowController : NSWindowController

- (instancetype)initWithFileURL:(NSURL *)fileURL;

- (void)saveWindowFrame;

@end

NS_ASSUME_NONNULL_END
