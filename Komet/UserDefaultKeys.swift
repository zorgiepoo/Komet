//
//  UserDefaultKeys.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/31/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

let ZGMessageFontNameKey = "ZGEditorFontName"
let ZGMessageFontPointSizeKey = "ZGEditorFontPointSize"

let ZGCommentsFontNameKey = "ZGCommentsFontName"
let ZGCommentsFontPointSizeKey = "ZGCommentsFontPointSize"

let ZGEditorRecommendedSubjectLengthLimitKey = "ZGEditorRecommendedSubjectLengthLimit"
let ZGEditorRecommendedSubjectLengthLimitEnabledKey = "ZGEditorRecommendedSubjectLengthLimitEnabled"

let ZGEditorRecommendedBodyLineLengthLimitKey = "ZGEditorRecommendedBodyLineLengthLimit"
let ZGEditorRecommendedBodyLineLengthLimitEnabledKey = "ZGEditorRecommendedBodyLineLengthLimitEnabled"

let ZGEditorAutomaticNewlineInsertionAfterSubjectKey = "ZGEditorAutomaticNewlineInsertionAfterSubject"

let ZGWindowStyleThemeKey = "ZGWindowStyleTheme"
let ZGWindowVibrancyKey = "ZGWindowVibrancy"

let ZGResumeIncompleteSessionKey = "ZGResumeIncompleteSession"
let ZGResumeIncompleteSessionTimeoutIntervalKey = "ZGResumeIncompleteSessionTimeoutInterval"

let ZGDisableSpellCheckingAndCorrectionForSquashesKey = "ZGDisableSpellCheckingAndCorrectionForSquashes"
let ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashesKey = "ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashes"

let ZGDetectHGCommentStyleForSquashesKey = "ZGDetectHGCommentStyleForSquashes"

let ZGAssumeVersionControlledFileKey = "ZGAssumeVersionControlledFile"

let ZGCommitTextViewContinuousSpellCheckingKey = "ZGCommitTextViewContinuousSpellChecking"
let ZGCommitTextViewAutomaticSpellingCorrectionKey = "ZGCommitTextViewAutomaticSpellingCorrection"
let ZGCommitTextViewAutomaticTextReplacementKey = "ZGCommitTextViewAutomaticTextReplacement"

let ZGEnableBetaUpdatesKey = "ZGEnableBetaUpdates"

// Environment options for test automation
let ZGBreadcrumbsURLKey = "ZGBreadcrumbsURL"
let ZGProjectNameKey = "ZGProjectName"

// This extension is for creating a KeyPath for Preferences to observe if the window style changes
extension UserDefaults
{
	@objc dynamic var ZGWindowStyleTheme: Any?
	{
		get {
			return object(forKey: ZGWindowStyleThemeKey)
		}
		set {
			set(newValue, forKey: ZGWindowStyleThemeKey)
		}
	}
}
