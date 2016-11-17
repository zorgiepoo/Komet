//
//  ZGCommitTextView.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGCommitTextView.h"

#define ZGCommitTextViewContinuousSpellCheckingKey @"ZGCommitTextViewContinuousSpellChecking"
#define ZGCommitTextViewAutomaticSpellingCorrectionKey @"ZGCommitTextViewAutomaticSpellingCorrection"
#define ZGCommitTextViewAutomaticTextReplacementKey @"ZGCommitTextViewAutomaticTextReplacement"

@implementation ZGCommitTextView

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		[defaults registerDefaults:@{ZGCommitTextViewContinuousSpellCheckingKey : @YES, ZGCommitTextViewAutomaticSpellingCorrectionKey : @([NSSpellChecker isAutomaticSpellingCorrectionEnabled]), ZGCommitTextViewAutomaticTextReplacementKey : @([NSSpellChecker isAutomaticTextReplacementEnabled])}];
	});
}

- (void)zgLoadDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[super setContinuousSpellCheckingEnabled:[defaults boolForKey:ZGCommitTextViewContinuousSpellCheckingKey]];
	[super setAutomaticSpellingCorrectionEnabled:[defaults boolForKey:ZGCommitTextViewAutomaticSpellingCorrectionKey]];
	[super setAutomaticTextReplacementEnabled:[defaults boolForKey:ZGCommitTextViewAutomaticTextReplacementKey]];
}

- (void)setContinuousSpellCheckingEnabled:(BOOL)continuousSpellCheckingEnabled
{
	[[NSUserDefaults standardUserDefaults] setBool:continuousSpellCheckingEnabled forKey:ZGCommitTextViewContinuousSpellCheckingKey];
	
	[super setContinuousSpellCheckingEnabled:continuousSpellCheckingEnabled];
}

- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)automaticSpellingCorrectionEnabled
{
	[[NSUserDefaults standardUserDefaults] setBool:automaticSpellingCorrectionEnabled forKey:ZGCommitTextViewAutomaticSpellingCorrectionKey];
	
	[super setAutomaticSpellingCorrectionEnabled:automaticSpellingCorrectionEnabled];
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

@end
