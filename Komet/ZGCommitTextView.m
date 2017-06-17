//
//  ZGCommitTextView.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGCommitTextView.h"
#import "ZGUserDefaults.h"

#define ZGCommitTextViewContinuousSpellCheckingKey @"ZGCommitTextViewContinuousSpellChecking"
#define ZGCommitTextViewAutomaticTextReplacementKey @"ZGCommitTextViewAutomaticTextReplacement"

#define ZGTouchBarIdentifier @"org.zgcoder.Komet.67e9f8738561"
#define ZGTouchBarIdentifierCancel @"zgCancelIdentifier"
#define ZGTouchBarIdentifierCommit @"zgCommitIdentifier"

@implementation ZGCommitTextView

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		[defaults registerDefaults:@{ZGCommitTextViewContinuousSpellCheckingKey : @YES,
									 ZGCommitTextViewAutomaticTextReplacementKey : @([NSSpellChecker isAutomaticTextReplacementEnabled])}];
	});
}

- (void)zgLoadDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[super setContinuousSpellCheckingEnabled:[defaults boolForKey:ZGCommitTextViewContinuousSpellCheckingKey]];
	[super setAutomaticSpellingCorrectionEnabled:ZGReadDefaultEnableAutomaticSpellingCorrection()];
	[super setAutomaticTextReplacementEnabled:[defaults boolForKey:ZGCommitTextViewAutomaticTextReplacementKey]];
}

- (void)setContinuousSpellCheckingEnabled:(BOOL)continuousSpellCheckingEnabled
{
	[[NSUserDefaults standardUserDefaults] setBool:continuousSpellCheckingEnabled forKey:ZGCommitTextViewContinuousSpellCheckingKey];
	
	[super setContinuousSpellCheckingEnabled:continuousSpellCheckingEnabled];
}

- (void)setAutomaticTextReplacementEnabled:(BOOL)automaticTextReplacementEnabled
{
	[[NSUserDefaults standardUserDefaults] setBool:automaticTextReplacementEnabled forKey:ZGCommitTextViewAutomaticTextReplacementKey];
	
	[super setAutomaticTextReplacementEnabled:automaticTextReplacementEnabled];
}

- (IBAction)selectAll:(id)sender
{
	if (self.zgCommitViewDelegate != nil)
	{
		[self.zgCommitViewDelegate zgCommitViewSelectAll];
	}
	else
	{
		[super selectAll:sender];
	}
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

static NSCustomTouchBarItem *ZGCreateCustomTouchBarButton(NSString *identifier, NSString *title, id target, SEL action)
{
	NSCustomTouchBarItem *touchBarItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
	touchBarItem.view = [NSButton buttonWithTitle:title target:target action:action];
	touchBarItem.customizationLabel = title;
	return touchBarItem;
}

- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
	NSTouchBarItem *touchBarItem;
	if ([identifier isEqualToString:ZGTouchBarIdentifierCancel])
	{
		touchBarItem = ZGCreateCustomTouchBarButton(identifier, @"Cancel", self.zgCommitViewDelegate, @selector(zgCommitViewTouchCancel:));
	}
	else if ([identifier isEqualToString:ZGTouchBarIdentifierCommit])
	{
		touchBarItem = ZGCreateCustomTouchBarButton(identifier, @"Commit", self.zgCommitViewDelegate, @selector(zgCommitViewTouchCommit:));
	}
	else
	{
		touchBarItem = [super touchBar:touchBar makeItemForIdentifier:identifier];
	}
	return touchBarItem;
}

- (NSTouchBar *)makeTouchBar
{
	NSTouchBar *touchBar = [[NSTouchBar alloc] init];
	touchBar.customizationIdentifier = ZGTouchBarIdentifier;
	touchBar.delegate = self;
	touchBar.defaultItemIdentifiers = @[NSTouchBarItemIdentifierCharacterPicker, ZGTouchBarIdentifierCommit, NSTouchBarItemIdentifierCandidateList];
	touchBar.customizationAllowedItemIdentifiers = @[NSTouchBarItemIdentifierCharacterPicker, ZGTouchBarIdentifierCancel, ZGTouchBarIdentifierCommit, NSTouchBarItemIdentifierFlexibleSpace, NSTouchBarItemIdentifierCandidateList];
	return touchBar;
}

#pragma clang diagnostic pop

@end
