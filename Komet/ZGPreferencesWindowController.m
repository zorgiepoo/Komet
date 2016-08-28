//
//  ZGPreferencesWindowController.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGPreferencesWindowController.h"
#import "ZGUserDefaults.h"
#import "ZGUserDefaultsListener.h"

#define ZGToolbarFontsIdentifier @"fonts"
#define ZGToolbarWarningsIdentifier @"warnings"
#define ZGToolbarAdvancedIdentifier @"advanced"

typedef NS_ENUM(NSInteger, ZGSelectedFontType)
{
	ZGSelectedFontTypeMessage,
	ZGSelectedFontTypeComments
};

@implementation ZGPreferencesWindowController
{
	__weak id<ZGUserDefaultsListener> _delegate;
	
	IBOutlet NSView *_fontsView;
	IBOutlet NSView *_warningsView;
	IBOutlet NSView *_advancedView;
	
	IBOutlet NSTextField *_messageFontTextField;
	IBOutlet NSTextField *_commentsFontTextField;
	
	ZGSelectedFontType _selectedFontType;
	
	IBOutlet NSTextField *_recommendedSubjectLengthLimitTextField;
	IBOutlet NSButton *_recommendedSubjectLengthLimitEnabledCheckbox;
	
	IBOutlet NSButton *_automaticNewlineInsertionAfterSubjectLineCheckbox;
}

- (instancetype)initWithDelegate:(id<ZGUserDefaultsListener>)delegate
{
	self = [super init];
	if (self != nil)
	{
		_delegate = delegate;
	}
	return self;
}

- (NSString *)windowNibName
{
	return @"Preferences";
}

- (void)windowDidLoad
{
	_messageFontTextField.editable = NO;
	_commentsFontTextField.editable = NO;
	
	[self showFonts:nil];
}

- (IBAction)showFonts:(id)__unused sender
{
	self.window.contentView = _fontsView;
	[self.window.toolbar setSelectedItemIdentifier:ZGToolbarFontsIdentifier];
	
	NSFont *messageFont = ZGReadDefaultMessageFont();
	NSFont *commentsFont = ZGReadDefaultCommentsFont();
	
	[self updateFont:messageFont atTextField:_messageFontTextField];
	[self updateFont:commentsFont atTextField:_commentsFontTextField];
}

- (void)updateFont:(NSFont *)font atTextField:(NSTextField *)textField
{
	textField.font = font;
	textField.stringValue = [NSString stringWithFormat:@"%@ - %0.1f", font.fontName, font.pointSize];
}

- (void)showFontPromptWithSelectedFont:(NSFont *)selectedFont selectedFontType:(ZGSelectedFontType)selectedFontType
{
	_selectedFontType = selectedFontType;
	
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:selectedFont isMultiple:NO];
	[fontManager orderFrontFontPanel:nil];
}

- (IBAction)changeMessageFont:(id)__unused sender
{
	[self showFontPromptWithSelectedFont:ZGReadDefaultMessageFont() selectedFontType:ZGSelectedFontTypeMessage];
}

- (IBAction)changeCommentsFont:(id)__unused sender
{
	[self showFontPromptWithSelectedFont:ZGReadDefaultCommentsFont() selectedFontType:ZGSelectedFontTypeComments];
}

- (void)changeFont:(id)__unused sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = fontManager.selectedFont;
	
	if (selectedFont != nil)
	{
		NSFont *convertedFont = [fontManager convertFont:selectedFont];
		
		switch (_selectedFontType)
		{
			case ZGSelectedFontTypeMessage:
				ZGWriteDefaultMessageFont(convertedFont);
				[_delegate userDefaultsChangedMessageFont];
				[self updateFont:convertedFont atTextField:_messageFontTextField];
				break;
			case ZGSelectedFontTypeComments:
				ZGWriteDefaultCommentsFont(convertedFont);
				[_delegate userDefaultsChangedCommentsFont];
				[self updateFont:convertedFont atTextField:_commentsFontTextField];
				break;
		}
	}
}

- (IBAction)showWarnings:(id)__unused sender
{
	self.window.contentView = _warningsView;
	[self.window.toolbar setSelectedItemIdentifier:ZGToolbarWarningsIdentifier];
	
	_recommendedSubjectLengthLimitTextField.integerValue = (NSInteger)ZGReadDefaultRecommendedSubjectLengthLimit();
	
	BOOL enabledSubjectLengthLimit = ZGReadDefaultRecommendedSubjectLengthLimitEnabled();
	_recommendedSubjectLengthLimitEnabledCheckbox.state = (enabledSubjectLengthLimit ? NSOnState : NSOffState);
	_recommendedSubjectLengthLimitTextField.enabled = enabledSubjectLengthLimit;
}

- (IBAction)changeRecommendedSubjectLengthLimitEnabled:(id)__unused sender
{
	BOOL enabled = (_recommendedSubjectLengthLimitEnabledCheckbox.state == NSOnState);
	
	ZGWriteDefaultRecommendedSubjectLengthLimitEnabled(enabled);
	_recommendedSubjectLengthLimitTextField.enabled = enabled;
	
	[_delegate userDefaultsChangedRecommendedSubjectLengthLimit];
}

- (IBAction)changeRecommendedSubjectLengthLimit:(id)__unused sender
{
	ZGWriteDefaultRecommendedSubjectLengthLimit((NSUInteger)_recommendedSubjectLengthLimitTextField.integerValue);
	[_delegate userDefaultsChangedRecommendedSubjectLengthLimit];
}

- (IBAction)showAdvanced:(id)__unused sender
{
	self.window.contentView = _advancedView;
	[self.window.toolbar setSelectedItemIdentifier:ZGToolbarAdvancedIdentifier];
	
	BOOL automaticInsertion = ZGReadDefaultAutomaticNewlineInsertionAfterSubjectLine();
	_automaticNewlineInsertionAfterSubjectLineCheckbox.state = (automaticInsertion ? NSOnState : NSOffState);
}

- (IBAction)changeAutomaticNewlineInsertionAfterSubjectLine:(id)__unused sender
{
	ZGWriteDefaultAutomaticNewlineInsertionAfterSubjectLine(_automaticNewlineInsertionAfterSubjectLineCheckbox.state == NSOnState);
}

@end
