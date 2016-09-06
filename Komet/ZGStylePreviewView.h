//
//  ZGStylePreviewView.h
//  Komet
//
//  Created by Trevor Fountain on 9/6/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

@interface ZGStylePreviewView : NSView

@property (strong, atomic) IBOutlet NSTextFieldCell *barTextLabel;
@property (strong, atomic) IBOutlet NSView *barView;
@property (strong, atomic) IBOutlet NSBox *lineBox;
@property (strong, atomic) IBOutlet NSTextField *messageText;
@property (strong, atomic) IBOutlet NSTextField *commentText;

@end
