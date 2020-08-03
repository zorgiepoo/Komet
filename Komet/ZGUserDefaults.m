//
//  ZGUserDefaults.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGUserDefaults.h"
#import "ZGWindowStyle.h"

#define ZGMessageFontNameKey @"ZGEditorFontName"
#define ZGMessageFontPointSizeKey @"ZGEditorFontPointSize"

#define ZGCommentsFontNameKey @"ZGCommentsFontName"
#define ZGCommentsFontPointSizeKey @"ZGCommentsFontPointSize"

#define ZGEditorRecommendedSubjectLengthLimitKey @"ZGEditorRecommendedSubjectLengthLimit"
#define ZGEditorRecommendedSubjectLengthLimitEnabledKey @"ZGEditorRecommendedSubjectLengthLimitEnabled"

#define ZGEditorRecommendedBodyLineLengthLimitKey @"ZGEditorRecommendedBodyLineLengthLimit"
#define ZGEditorRecommendedBodyLineLengthLimitEnabledKey @"ZGEditorRecommendedBodyLineLengthLimitEnabled"

#define ZGEditorAutomaticNewlineInsertionAfterSubjectKey @"ZGEditorAutomaticNewlineInsertionAfterSubject"

#define ZGWindowStyleThemeKey @"ZGWindowStyleTheme"
#define ZGWindowVibrancyKey @"ZGWindowVibrancy"

#define ZGResumeIncompleteSessionKey @"ZGResumeIncompleteSession"
#define ZGResumeIncompleteSessionTimeoutIntervalKey @"ZGResumeIncompleteSessionTimeoutInterval"

#define ZGDisableSpellCheckingAndCorrectionForSquashesKey @"ZGDisableSpellCheckingAndCorrectionForSquashes"
#define ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashesKey @"ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashes"

#define ZGDetectHGCommentStyleForSquashesKey @"ZGDetectHGCommentStyleForSquashes"

static NSFont *ZGReadDefaultFont(NSString *fontNameDefaultsKey, NSString *fontSizeDefaultsKey)
{
	NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:fontNameDefaultsKey];
	CGFloat fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey:fontSizeDefaultsKey];
	
	NSFont *font;
	if (fontName.length == 0)
	{
		font = [NSFont userFixedPitchFontOfSize:fontSize];
	}
	else
	{
		NSFont *userFont = [NSFont fontWithName:fontName size:fontSize];
		if (userFont != nil)
		{
			font = userFont;
		}
		else
		{
			font = [NSFont userFixedPitchFontOfSize:fontSize];
		}
	}
	return font;
}

static void ZGWriteDefaultFont(NSFont *font, NSString *fontNameKey, NSString *fontPointSizeKey)
{
	[[NSUserDefaults standardUserDefaults] setObject:font.fontName forKey:fontNameKey];
	[[NSUserDefaults standardUserDefaults] setObject:@(font.pointSize) forKey:fontPointSizeKey];
}

void ZGRegisterDefaultMessageFont(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGMessageFontNameKey : @"", ZGMessageFontPointSizeKey : @(0.0)}];
}

NSFont *ZGReadDefaultMessageFont(void)
{
	return ZGReadDefaultFont(ZGMessageFontNameKey, ZGMessageFontPointSizeKey);
}

void ZGWriteDefaultMessageFont(NSFont *font)
{
	ZGWriteDefaultFont(font, ZGMessageFontNameKey, ZGMessageFontPointSizeKey);
}

void ZGRegisterDefaultCommentsFont(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGCommentsFontNameKey : @"", ZGCommentsFontPointSizeKey : @(0.0)}];
}

NSFont *ZGReadDefaultCommentsFont(void)
{
	return ZGReadDefaultFont(ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey);
}

void ZGWriteDefaultCommentsFont(NSFont *font)
{
	ZGWriteDefaultFont(font, ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey);
}

void ZGRegisterDefaultRecommendedSubjectLengthLimit(void)
{
	// This is the max subject length GitHub uses before the subject overflows
	// Not using 50 because I think it may be too irritating of a default for Mac users
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGEditorRecommendedSubjectLengthLimitKey : @(69)}];
}

NSUInteger ZGReadDefaultRecommendedSubjectLengthLimit(void)
{
	NSUInteger limitRead = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:ZGEditorRecommendedSubjectLengthLimitKey];
	return MIN(limitRead, 1000LU);
}

void ZGWriteDefaultRecommendedSubjectLengthLimit(NSUInteger recommendedSubjectLengthLimit)
{
	[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)recommendedSubjectLengthLimit forKey:ZGEditorRecommendedSubjectLengthLimitKey];
}

void ZGRegisterDefaultRecommendedSubjectLengthLimitEnabled(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGEditorRecommendedSubjectLengthLimitEnabledKey : @(YES)}];
}

BOOL ZGReadDefaultRecommendedSubjectLengthLimitEnabled(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGEditorRecommendedSubjectLengthLimitEnabledKey];
}

void ZGWriteDefaultRecommendedSubjectLengthLimitEnabled(BOOL enabled)
{
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ZGEditorRecommendedSubjectLengthLimitEnabledKey];
}

void ZGRegisterDefaultRecommendedBodyLineLengthLimit(void)
{
	// 72 seems to be the standard recommended body line length limit for git
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGEditorRecommendedBodyLineLengthLimitKey : @(72)}];
}

NSUInteger ZGReadDefaultRecommendedBodyLineLengthLimit(void)
{
	NSUInteger limitRead = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:ZGEditorRecommendedBodyLineLengthLimitKey];
	return MIN(limitRead, 1000LU);
}

void ZGWriteDefaultRecommendedBodyLineLengthLimit(NSUInteger recommendedBodyLineLengthLimit)
{
	[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)recommendedBodyLineLengthLimit forKey:ZGEditorRecommendedBodyLineLengthLimitKey];
}

void ZGRegisterDefaultRecommendedBodyLineLengthLimitEnabled(void)
{
	// Having a recommendation limit for body lines could be irritating as a default, so we disable it by default
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGEditorRecommendedBodyLineLengthLimitEnabledKey : @(NO)}];
}

BOOL ZGReadDefaultRecommendedBodyLineLengthLimitEnabled(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGEditorRecommendedBodyLineLengthLimitEnabledKey];
}

void ZGWriteDefaultRecommendedBodyLineLengthLimitEnabled(BOOL enabled)
{
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ZGEditorRecommendedBodyLineLengthLimitEnabledKey];
}

void ZGRegisterDefaultAutomaticNewlineInsertionAfterSubjectLine(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGEditorAutomaticNewlineInsertionAfterSubjectKey : @(YES)}];
}

BOOL ZGReadDefaultAutomaticNewlineInsertionAfterSubjectLine(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGEditorAutomaticNewlineInsertionAfterSubjectKey];
}

void ZGWriteDefaultAutomaticNewlineInsertionAfterSubjectLine(BOOL automaticNewlineInsertionAfterSubjectLine)
{
	[[NSUserDefaults standardUserDefaults] setBool:automaticNewlineInsertionAfterSubjectLine forKey:ZGEditorAutomaticNewlineInsertionAfterSubjectKey];
}

ZGWindowStyleTheme ZGReadDefaultWindowStyleTheme(NSAppearance * _Nullable effectiveAppearance)
{
	ZGWindowStyleTheme theme;
	NSNumber *themeDefault = [[NSUserDefaults standardUserDefaults] objectForKey:ZGWindowStyleThemeKey];
	if (themeDefault == nil || ![themeDefault isKindOfClass:[NSNumber class]])
	{
		BOOL darkMode;
		if (@available(macOS 10.14, *))
		{
			NSAppearanceName appearanceName = [effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
			darkMode = [appearanceName isEqualToString:NSAppearanceNameDarkAqua];
		}
		else
		{
			darkMode = NO;
		}
		theme = darkMode ? ZGWindowStyleThemeDark : ZGWindowStyleThemePlain;
	}
	else
	{
		NSUInteger themeValue = [themeDefault unsignedIntegerValue];
		theme = (themeValue > ZGWindowStyleMaxTheme) ? ZGWindowStyleThemePlain : themeValue;
	}
	return theme;
}

void ZGWriteDefaultStyleTheme(ZGWindowStyleTheme theme)
{
	[[NSUserDefaults standardUserDefaults] setObject:@(theme) forKey:ZGWindowStyleThemeKey];
}

void ZGRegisterDefaultWindowVibrancy(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGWindowVibrancyKey : @(NO)}];
}

BOOL ZGReadDefaultWindowVibrancy(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGWindowVibrancyKey];
}

void ZGWriteDefaultWindowVibrancy(BOOL windowVibrancy)
{
	[[NSUserDefaults standardUserDefaults] setBool:windowVibrancy forKey:ZGWindowVibrancyKey];
}

void ZGRegisterDefaultResumeIncompleteSession(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGResumeIncompleteSessionKey : @(YES)}];
}

BOOL ZGReadDefaultResumeIncompleteSession(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGResumeIncompleteSessionKey];
}

void ZGWriteDefaultResumeIncompleteSession(BOOL resumeIncompleteSession)
{
	[[NSUserDefaults standardUserDefaults] setBool:resumeIncompleteSession forKey:ZGResumeIncompleteSessionKey];
}

void ZGRegisterDefaultResumeIncompleteSessionTimeoutInterval(void)
{
	NSTimeInterval defaultTimeoutInterval = 60.0 * 60; // around 1 hour
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGResumeIncompleteSessionTimeoutIntervalKey : @(defaultTimeoutInterval)}];
}

NSTimeInterval ZGReadDefaultResumeIncompleteSessionTimeoutInterval(void)
{
	NSTimeInterval timeoutRead = [[NSUserDefaults standardUserDefaults] doubleForKey:ZGResumeIncompleteSessionTimeoutIntervalKey];
	NSTimeInterval minTimeout = 0.0;
	NSTimeInterval maxTimeout = 60.0 * 60.0 * 24 * 7 * 5; // around a month
	return MIN(MAX(minTimeout, timeoutRead), maxTimeout);
}

void ZGRegisterDefaultDisableSpellCheckingAndCorrectionForSquashes(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGDisableSpellCheckingAndCorrectionForSquashesKey : @(YES)}];
}

BOOL ZGReadDefaultDisableSpellCheckingAndCorrectionForSquashes(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGDisableSpellCheckingAndCorrectionForSquashesKey];
}

void ZGRegisterDefaultDisableAutomaticNewlineInsertionAfterSubjectLineForSquashes(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashesKey : @(YES)}];
}

BOOL ZGReadDefaultDisableAutomaticNewlineInsertionAfterSubjectLineForSquashes(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashesKey];
}

void ZGRegisterDefaultDetectHGCommentStyleForSquashes(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ZGDetectHGCommentStyleForSquashesKey : @(YES)}];
}

BOOL ZGReadDefaultDetectHGCommentStyleForSquashes(void)
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ZGDetectHGCommentStyleForSquashesKey];
}
