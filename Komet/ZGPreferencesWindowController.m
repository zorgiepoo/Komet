//
//  ZGPreferencesWindowController.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGPreferencesWindowController.h"
#import "ZGUserDefaults.h"
#import "ZGUserDefaultsEditorListener.h"
#import "ZGUpdaterSettingsListener.h"
#import "ZGWindowStyle.h"

@import SparkleCore;

// We could have three different nibs and swap between them with view controllers
// But I kind of wanted to avoid unnecessary nib files (extra disk space, more runtime loading...)
// Currently our preference logic is not that complex

#define ZGToolbarFontsIdentifier @"fonts"
#define ZGToolbarWarningsIdentifier @"warnings"
#define ZGToolbarAdvancedIdentifier @"advanced"
#define ZGToolbarStyleIdentifier @"style"

typedef NS_ENUM(NSInteger, ZGSelectedFontType)
{
	ZGSelectedFontTypeMessage,
	ZGSelectedFontTypeComments
};

@implementation ZGPreferencesWindowController
{
	__weak id<ZGUserDefaultsEditorListener> _editorListener;
	__weak id<ZGUpdaterSettingsListener> _updaterListener;
	
	IBOutlet NSView *_fontsView;
	IBOutlet NSView *_warningsView;
	IBOutlet NSView *_advancedView;
	IBOutlet NSView *_styleView;
	
	IBOutlet NSTextField *_messageFontTextField;
	IBOutlet NSTextField *_commentsFontTextField;
	
	ZGSelectedFontType _selectedFontType;
	
	IBOutlet NSTextField *_recommendedSubjectLengthLimitTextField;
	IBOutlet NSButton *_recommendedSubjectLengthLimitEnabledCheckbox;
	IBOutlet NSTextField *_recommendedSubjectLengthLimitDescriptionTextField;
	
	IBOutlet NSTextField *_recommendedBodyLineLengthLimitTextField;
	IBOutlet NSButton *_recommendedBodyLineLengthLimitEnabledCheckbox;
	IBOutlet NSTextField *_recommendedBodyLineLengthLimitDescriptionTextField;
	
	IBOutlet NSButton *_automaticNewlineInsertionAfterSubjectLineCheckbox;
	IBOutlet NSButton *_automaticallyInstallUpdatesCheckbox;
	
	IBOutlet NSButton *_defaultStyleButton;
	IBOutlet NSButton *_darkStyleButton;
	IBOutlet NSButton *_papyrusStyleButton;
	IBOutlet NSButton *_blueStyleButton;
	IBOutlet NSButton *_greenStyleButton;
	IBOutlet NSButton *_redStyleButton;
    IBOutlet NSButton *_vibrancySwitch;
}

- (instancetype)initWithEditorListener:(id<ZGUserDefaultsEditorListener>)editorListener updaterListener:(id<ZGUpdaterSettingsListener>)updaterListener
{
	self = [super init];
	if (self != nil)
	{
		_editorListener = editorListener;
		_updaterListener = updaterListener;
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
	
	_messageFontTextField.selectable = NO;
	_commentsFontTextField.selectable = NO;
	
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
				[_editorListener userDefaultsChangedMessageFont];
				[self updateFont:convertedFont atTextField:_messageFontTextField];
				break;
			case ZGSelectedFontTypeComments:
				ZGWriteDefaultCommentsFont(convertedFont);
				[_editorListener userDefaultsChangedCommentsFont];
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
	[self setTextField:_recommendedSubjectLengthLimitDescriptionTextField enabled:enabledSubjectLengthLimit];
	
	BOOL enabledBodyLineLengthLimit = ZGReadDefaultRecommendedBodyLineLengthLimitEnabled();
	_recommendedBodyLineLengthLimitEnabledCheckbox.state = (enabledBodyLineLengthLimit ? NSOnState : NSOffState);
	_recommendedBodyLineLengthLimitTextField.enabled = enabledBodyLineLengthLimit;
	[self setTextField:_recommendedBodyLineLengthLimitDescriptionTextField enabled:enabledBodyLineLengthLimit];
}

- (void)setTextField:(NSTextField *)textField enabled:(BOOL)enabled
{
	if (enabled)
	{
		textField.textColor = [NSColor controlTextColor];
	}
	else
	{
		textField.textColor = [NSColor disabledControlTextColor];
	}
}

- (IBAction)changeRecommendedSubjectLengthLimitEnabled:(id)__unused sender
{
	BOOL enabled = (_recommendedSubjectLengthLimitEnabledCheckbox.state == NSOnState);
	
	ZGWriteDefaultRecommendedSubjectLengthLimitEnabled(enabled);
	_recommendedSubjectLengthLimitTextField.enabled = enabled;
	[self setTextField:_recommendedSubjectLengthLimitDescriptionTextField enabled:enabled];
	
	[_editorListener userDefaultsChangedRecommendedLineLengthLimits];
}

- (IBAction)changeRecommendedSubjectLengthLimit:(id)__unused sender
{
	ZGWriteDefaultRecommendedSubjectLengthLimit((NSUInteger)_recommendedSubjectLengthLimitTextField.integerValue);
	[_editorListener userDefaultsChangedRecommendedLineLengthLimits];
}

- (IBAction)changeRecommendedBodyLineLengthLimitEnabled:(id)__unused sender
{
	BOOL enabled = (_recommendedBodyLineLengthLimitEnabledCheckbox.state == NSOnState);
	
	ZGWriteDefaultRecommendedBodyLineLengthLimitEnabled(enabled);
	_recommendedBodyLineLengthLimitTextField.enabled = enabled;
	[self setTextField:_recommendedBodyLineLengthLimitDescriptionTextField enabled:enabled];
	
	[_editorListener userDefaultsChangedRecommendedLineLengthLimits];
}

- (IBAction)changeRecommendedBodyLineLengthLimit:(id)__unused sender
{
	ZGWriteDefaultRecommendedBodyLineLengthLimit((NSUInteger)_recommendedBodyLineLengthLimitTextField.integerValue);
	[_editorListener userDefaultsChangedRecommendedLineLengthLimits];
}

- (IBAction)showAdvanced:(id)__unused sender
{
	self.window.contentView = _advancedView;
	[self.window.toolbar setSelectedItemIdentifier:ZGToolbarAdvancedIdentifier];
	
	BOOL automaticInsertion = ZGReadDefaultAutomaticNewlineInsertionAfterSubjectLine();
	_automaticNewlineInsertionAfterSubjectLineCheckbox.state = (automaticInsertion ? NSOnState : NSOffState);
	
	SPUUpdaterSettings *updaterSettings = [[SPUUpdaterSettings alloc] initWithHostBundle:[NSBundle mainBundle]];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	
	// This isn't a perfect check to see if we can update our app without any user interaction, but it's good enough for our purposes
	// (Sparkle has a better check, but it's not as simple/efficient. Even if we are wrong here, Sparkle still won't be able to install updates automatically).
	BOOL canWriteToApp = ([fileManager isWritableFileAtPath:bundlePath] && [fileManager isWritableFileAtPath:bundlePath.stringByDeletingLastPathComponent]);
	
	_automaticallyInstallUpdatesCheckbox.state = ((canWriteToApp && updaterSettings.automaticallyChecksForUpdates) ? NSOnState : NSOffState);
	_automaticallyInstallUpdatesCheckbox.enabled = canWriteToApp;
}

- (IBAction)changeAutomaticNewlineInsertionAfterSubjectLine:(id)__unused sender
{
	ZGWriteDefaultAutomaticNewlineInsertionAfterSubjectLine(_automaticNewlineInsertionAfterSubjectLineCheckbox.state == NSOnState);
}

- (IBAction)changeAutomaticallyInstallUpdates:(id)__unused sender
{
	[_updaterListener updaterSettingsChangedAutomaticallyInstallingUpdates:(_automaticallyInstallUpdatesCheckbox.state == NSOnState)];
}

- (IBAction)showStyles:(id)__unused sender {
	self.window.contentView = _styleView;
	[self.window.toolbar setSelectedItemIdentifier:ZGToolbarStyleIdentifier];
    
    _vibrancySwitch.state = (ZGReadDefaultWindowVibrancy() ? 1 : 0);
	
	NSString *activeStyle = ZGReadDefaultWindowStyle();
	if ([activeStyle isEqualToString:ZGWindowStyleDefault]) {
		_defaultStyleButton.state = NSOnState;
	} else if ([activeStyle isEqualToString:ZGWindowStyleDark]) {
		_darkStyleButton.state = NSOnState;
	} else if ([activeStyle isEqualToString:ZGWindowStylePapyrus]) {
		_papyrusStyleButton.state = NSOnState;
	} else if ([activeStyle isEqualToString:ZGWindowStyleBlue]) {
		_blueStyleButton.state = NSOnState;
	} else if ([activeStyle isEqualToString:ZGWindowStyleGreen]) {
		_greenStyleButton.state = NSOnState;
	} else if ([activeStyle isEqualToString:ZGWindowStyleRed]) {
		_redStyleButton.state = NSOnState;
	}
}

- (IBAction)setStyle:(NSButton *)sender {
	_defaultStyleButton.state = NSOffState;
	_darkStyleButton.state = NSOffState;
	_papyrusStyleButton.state = NSOffState;
	_blueStyleButton.state = NSOffState;
	_greenStyleButton.state = NSOffState;
	_redStyleButton.state = NSOffState;
	sender.state = NSOnState;
    
	if (sender == _defaultStyleButton) {
		ZGWriteDefaultStyle(ZGWindowStyleDefault);
	} else if (sender == _darkStyleButton) {
		ZGWriteDefaultStyle(ZGWindowStyleDark);
	} else if (sender == _papyrusStyleButton) {
		ZGWriteDefaultStyle(ZGWindowStylePapyrus);
	} else if (sender == _blueStyleButton) {
		ZGWriteDefaultStyle(ZGWindowStyleBlue);
	} else if (sender == _greenStyleButton) {
		ZGWriteDefaultStyle(ZGWindowStyleGreen);
	} else if (sender == _redStyleButton) {
		ZGWriteDefaultStyle(ZGWindowStyleRed);
	}
    
	[_editorListener userDefaultsChangedWindowStyle];
}

- (IBAction)setVibrancy:(NSButton *)sender {
    ZGWriteDefaultWindowVibrancy([sender state] == 1);
    
    [_editorListener userDefaultsChangedWindowVibrancy];
}

@end
