//
//  ZGUserDefaults.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGUserDefaults.h"

#define ZGMessageFontNameKey @"ZGEditorFontName"
#define ZGMessageFontPointSizeKey @"ZGEditorFontPointSize"

#define ZGCommentsFontNameKey @"ZGCommentsFontName"
#define ZGCommentsFontPointSizeKey @"ZGCommentsFontPointSize"

#define ZGEditorRecommendedSubjectLengthLimitKey @"ZGEditorRecommendedSubjectLengthLimit"

#define ZGEditorRecommendedSubjectLengthLimitEnabledKey @"ZGEditorRecommendedSubjectLengthLimitEnabled"

#define ZGEditorAutomaticNewlineInsertionAfterSubjectKey @"ZGEditorAutomaticNewlineInsertionAfterSubject"

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
	return (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:ZGEditorRecommendedSubjectLengthLimitKey];
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
