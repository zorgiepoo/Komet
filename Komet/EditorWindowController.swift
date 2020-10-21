//
//  EditorWindowController.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/17/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Foundation
import AppKit

let ZGEditorWindowFrameNameKey = "ZGEditorWindowFrame"
let APP_SUPPORT_DIRECTORY_NAME = "Komet"

let MAX_CHARACTER_COUNT_FOR_NOT_DRAWING_BACKGROUND = 132690

enum VersionControlType {
	case git
	case hg
	case svn
}

@objc class ZGEditorWindowController: NSWindowController, ZGUserDefaultsEditorListener, NSTextStorageDelegate, NSLayoutManagerDelegate, NSTextViewDelegate, ZGCommitViewDelegate {
	
	private let fileURL: URL
	private let temporaryDirectoryURL: URL?
	private let tutorialMode: Bool
	private let breadcrumbs: ZGBreadcrumbs?
	
	private let initiallyContainedEmptyContent: Bool
	private let isSquashMessage: Bool
	private let commentSectionLength: Int
	private let versionControlType: VersionControlType
	private let commentVersionControlType: VersionControlType
	private let projectNameDisplay: String
	private let initialPlainText: String
	private let resumedFromSavedCommit: Bool
	
	private var style: ZGWindowStyle
	private var preventAccidentalNewline: Bool = false
	private var effectiveAppearanceObserver: NSKeyValueObservation? = nil
	
	@IBOutlet var topBar: NSView!
	@IBOutlet var horizontalBarDivider: NSBox!
	@IBOutlet var textView: ZGCommitTextView!
	@IBOutlet var scrollView: NSScrollView!
	@IBOutlet var contentView: NSVisualEffectView!
	@IBOutlet var commitLabelTextField: NSTextField!
	@IBOutlet var cancelButton: NSButtonCell!
	@IBOutlet var commitButton: NSButton!
	
	// MARK: Static functions
	
	private static func styleTheme(defaultTheme: ZGWindowStyleDefaultTheme, effectiveAppearance: NSAppearance) -> ZGWindowStyleTheme {
		if !defaultTheme.automatic {
			return defaultTheme.theme
		} else {
			let appearanceName = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
			let darkMode = (appearanceName == .darkAqua)
			
			return darkMode ? .dark : .plain
		}
	}
	
	private static func isCommentLine(_ line: String, versionControlType: VersionControlType) -> Bool {
		let prefix: String
		let suffix: String
		
		switch versionControlType {
		case .git:
			prefix = "#"
			suffix = ""
		case .hg:
			prefix = "HG:"
			suffix = ""
		case .svn:
			prefix = "--"
			suffix = "--"
		}
		
		// Note a line that is "--" could have the prefix and suffix the same, but we want to make sure it's at least "--...--" length long
		return line.hasPrefix(prefix) && line.hasSuffix(suffix) && line.count >= prefix.count + suffix.count
	}
	
	private static func hasSingleCommentLineMarker(versionControlType: VersionControlType) -> Bool {
		switch versionControlType {
		case .git:
			return false
		case .hg:
			return false
		case .svn:
			return true
		}
	}
	
	// The comment range should begin at the line that starts with a comment string and extend to the end of the file.
	// Additionally, there should be no content lines (i.e, non comment lines) within this section
	// (exception: unless we're dealing with svn which only has a starting point for comments)
	// This should only be computed once, before the user gets a chance to edit the content
	private static func commentSectionLength(plainText: String, versionControlType: VersionControlType) -> Int {
		let plainTextEndIndex = plainText.endIndex
		var characterIndex = String.Index(utf16Offset: 0, in: plainText)
		var lineStartIndex = String.Index(utf16Offset: 0, in: plainText)
		var lineEndIndex = String.Index(utf16Offset: 0, in: plainText)
		var contentEndIndex = String.Index(utf16Offset: 0, in: plainText)
		
		var foundCommentSection: Bool = false
		var commentSectionCharacterIndex: String.Index = String.Index(utf16Offset: 0, in: plainText)
		
		while characterIndex < plainTextEndIndex {
			plainText.getLineStart(&lineStartIndex, end: &lineEndIndex, contentsEnd: &contentEndIndex, for: characterIndex ..< characterIndex)
			
			let line = String(plainText[lineStartIndex ..< contentEndIndex])
			
			let commentLine = isCommentLine(line, versionControlType: versionControlType)
			
			if !commentLine && foundCommentSection && line.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
				// If we found a content line that is not empty, then we have to find a better starting point for the comment section
				foundCommentSection = false
			} else if commentLine && !foundCommentSection {
				foundCommentSection = true
				commentSectionCharacterIndex = characterIndex
				
				// If there's only a single comment line marker, then we're done'
				if hasSingleCommentLineMarker(versionControlType: versionControlType) {
					break
				}
			}
			
			characterIndex = lineEndIndex
		}
		
		return foundCommentSection ? (plainText.distance(from: commentSectionCharacterIndex, to: plainTextEndIndex)) : 0
	}
	
	// The content range should extend to before the comments, only allowing one trailing newline in between the comments and content
	// Make sure to scan from the bottom to top
	private static func commitTextLength(plainText: String, commentLength: Int) -> Int {
		var bestEndCharacterIndex = plainText.index(plainText.endIndex, offsetBy: -commentLength)
		var passedNewline = false
		
		let startIndex = plainText.startIndex
		while bestEndCharacterIndex > startIndex {
			let priorCharacterIndex = plainText.index(before: bestEndCharacterIndex)
			
			let character = plainText[priorCharacterIndex]
			if character == "\n" {
				bestEndCharacterIndex = priorCharacterIndex
				
				if passedNewline {
					break;
				} else {
					passedNewline = true
				}
			} else {
				break
			}
		}
		
		return plainText.distance(from: startIndex, to: bestEndCharacterIndex)
	}
	
	private static func projectName(fileManager: FileManager) -> String {
		return URL(fileURLWithPath:fileManager.currentDirectoryPath).lastPathComponent
	}
	
	// MARK: Initialization
	
	static func registerDefaults() {
		ZGRegisterDefaultMessageFont()
		ZGRegisterDefaultCommentsFont()
		ZGRegisterDefaultRecommendedSubjectLengthLimitEnabled()
		ZGRegisterDefaultRecommendedSubjectLengthLimit()
		ZGRegisterDefaultRecommendedBodyLineLengthLimitEnabled()
		ZGRegisterDefaultRecommendedBodyLineLengthLimit()
		ZGRegisterDefaultAutomaticNewlineInsertionAfterSubjectLine()
		ZGRegisterDefaultResumeIncompleteSession()
		ZGRegisterDefaultResumeIncompleteSessionTimeoutInterval()
		ZGRegisterDefaultWindowVibrancy()
		ZGRegisterDefaultDisableSpellCheckingAndCorrectionForSquashes()
		ZGRegisterDefaultDisableAutomaticNewlineInsertionAfterSubjectLineForSquashes()
		ZGRegisterDefaultDetectHGCommentStyleForSquashes()
		ZGRegisterDefaultBreadcrumbsURL()
	}
	
	required init(fileURL: URL, temporaryDirectoryURL: URL?, tutorialMode: Bool) {
		self.fileURL = fileURL
		self.temporaryDirectoryURL = temporaryDirectoryURL
		self.tutorialMode = tutorialMode
		
		breadcrumbs = ZGReadDefaultBreadcrumbsURL().flatMap({ ZGBreadcrumbs(writingTo: $0) })
		
		style = ZGWindowStyle.init(theme: Self.styleTheme(defaultTheme: ZGReadDefaultWindowStyleTheme(), effectiveAppearance: NSApp.effectiveAppearance))
		
		// Detect squash message
		let loadedPlainString: String
		do {
			let plainStringCandidate = try String(contentsOf: self.fileURL, encoding: .utf8)
			
			// It's unlikely we'll get content that has no line break, but if we do,
			// just insert a newline character because Komet won't be able to deal with the content otherwise
			let lineCount = plainStringCandidate.components(separatedBy: .newlines).count
			loadedPlainString = (lineCount <= 1) ? "\n" : plainStringCandidate
			
			// Detect heuristically if this is a squash/rebase in git or hg
			// Scan the entire string contents for simplicity and handle both git and hg (with histedit extension)
			// Also test if the filename contains "rebase"
			isSquashMessage = fileURL.lastPathComponent.contains("rebase") || loadedPlainString.contains("= use commit")
		} catch {
			fatalError("Failed to parse commit data: \(error)")
		}
		
		// Detect version control type
		let fileManager = FileManager()
		let parentURL = self.fileURL.deletingLastPathComponent()
		let versionControlType: VersionControlType
		if tutorialMode {
			versionControlType = .git
			self.projectNameDisplay = self.fileURL.lastPathComponent
		} else if parentURL.lastPathComponent == ".git" {
			// We don't *have* to detect this for gits because we could look at the current working directory first,
			// but I want to rely on the current working directory as a last resort.
			
			versionControlType = .git
			self.projectNameDisplay = parentURL.deletingLastPathComponent().lastPathComponent
		} else {
			let lastPathComponent = self.fileURL.lastPathComponent
			if lastPathComponent.hasPrefix("hg-") {
				versionControlType = .hg
			} else if lastPathComponent.hasPrefix("svn-") {
				versionControlType = .svn
			} else {
				versionControlType = .git
			}
			
			self.projectNameDisplay = Self.projectName(fileManager: fileManager)
		}
		
		self.versionControlType = versionControlType
		
		commentVersionControlType =
			(isSquashMessage && versionControlType == .hg && ZGReadDefaultDetectHGCommentStyleForSquashes()) ?
			.git : versionControlType
		
		// Detect if there's empty content
		let loadedCommentSectionLength = Self.commentSectionLength(plainText: loadedPlainString, versionControlType: versionControlType)
		let loadedCommitLength = Self.commitTextLength(plainText: loadedPlainString, commentLength: loadedCommentSectionLength)
		
		let loadedContent = loadedPlainString[loadedPlainString.startIndex ..< loadedPlainString.index(loadedPlainString.startIndex, offsetBy: loadedCommitLength)]
		
		initiallyContainedEmptyContent = (loadedContent.trimmingCharacters(in: .newlines).count == 0)
		
		// Check if we have any incomplete commit message available
		// Load the incomplete commit message contents if our content is initially empty
		let lastSavedCommitMessage: String?
		if !self.tutorialMode && ZGReadDefaultResumeIncompleteSession() {
			if let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
				let supportDirectory = applicationSupportURL.appendingPathComponent(APP_SUPPORT_DIRECTORY_NAME)
				let projectName = Self.projectName(fileManager: fileManager)
				
				let lastCommitURL = supportDirectory.appendingPathComponent(projectName)
				
				do {
					let reachable = try lastCommitURL.checkResourceIsReachable()
					if reachable {
						defer {
							// Always remove the last commit file on every launch
							let _ = try? fileManager.removeItem(at: lastCommitURL)
						}
						
						let resource = try lastCommitURL.resourceValues(forKeys: [.attributeModificationDateKey])
						let lastModifiedDate = resource.attributeModificationDate
						
						// Use a timeout interval for using the last incomplete commit message
						// If too much time passes by, chances are the user may want to start anew
						let timeoutInterval = ZGReadDefaultResumeIncompleteSessionTimeoutInterval()
						let intervalSinceLastSavedCommitMessage = lastModifiedDate.flatMap({ Date().timeIntervalSince($0) }) ?? 0.0
						
						if initiallyContainedEmptyContent && intervalSinceLastSavedCommitMessage >= 0.0 && intervalSinceLastSavedCommitMessage <= timeoutInterval {
							lastSavedCommitMessage = try String(contentsOf: lastCommitURL, encoding: .utf8)
						} else {
							lastSavedCommitMessage = nil
						}
					} else {
						lastSavedCommitMessage = nil
					}
				} catch {
					print("Failed to load last saved commit message: \(error)")
					lastSavedCommitMessage = nil
				}
			} else {
				print("Failed to find application support directory")
				lastSavedCommitMessage = nil
			}
		} else {
			lastSavedCommitMessage = nil
		}
		
		if let savedCommitMessage = lastSavedCommitMessage {
			initialPlainText = savedCommitMessage.appending(loadedPlainString)
			commentSectionLength = Self.commentSectionLength(plainText: initialPlainText, versionControlType: commentVersionControlType)
			resumedFromSavedCommit = true
		} else {
			initialPlainText = loadedPlainString
			commentSectionLength = loadedCommentSectionLength
			resumedFromSavedCommit = false
		}
		
		super.init(window: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		effectiveAppearanceObserver?.invalidate()
	}
	
	override var windowNibName: String {
		return "Commit Editor"
	}
	
//	private func saveWindowFrame() {
//		self.window?.saveFrame(usingName: ZGEditorWindowFrameNameKey)
//	}
	
	private func currentPlainText() -> String {
		let textStorage = textView.textStorage
		return textStorage?.string ?? ""
	}
	
	private func updateTextViewDrawingBackground() {
		let plainText = currentPlainText()
		
		if #available(macOS 10.15.7, *) {
			textView.drawsBackground = false
		} else {
			// Having drawBackgrounds set to NO appears to cause issues when there is a lot of content.
			// Work around this by setting drawBackgrounds to YES in such cases.
			// In some themes the visual look may not be too different.
			// Note: I cannot reproduce this issue on 10.15.7, so I'm assuming this is no longer an issue there
			textView.drawsBackground = (plainText.utf16.count > MAX_CHARACTER_COUNT_FOR_NOT_DRAWING_BACKGROUND)
		}
	}
	
	private func updateCurrentStyle() {
		// Style top bar
		do {
			topBar.wantsLayer = true
			topBar.layer?.backgroundColor = style.barColor.cgColor
			
			// Setting the top bar appearance will provide us a proper border for the commit button in dark and light themes
			topBar.appearance = style.appearance
		}
		
		// Style top bar buttons
		do {
			commitLabelTextField.textColor = style.barTextColor
			
			let commitTitle = NSMutableAttributedString(attributedString: commitButton.attributedTitle)
			commitTitle.addAttribute(.foregroundColor, value: style.barTextColor, range: NSMakeRange(0, commitTitle.length))
			commitButton.attributedTitle = commitTitle
			
			let cancelTitle = NSMutableAttributedString(attributedString: cancelButton.attributedTitle)
			cancelTitle.addAttribute(.foregroundColor, value: style.barTextColor, range: NSMakeRange(0, cancelTitle.length))
			cancelButton.attributedTitle = cancelTitle
		}
		
		// Horizontal line bar divider
		horizontalBarDivider.fillColor = style.dividerLineColor
		
		// Style text
		do {
			textView.wantsLayer = true
			updateTextViewDrawingBackground()
			textView.insertionPointColor = style.textColor
			
			let textHighlightColor = style.textHighlightColor ?? NSColor.selectedTextColor
			textView.selectedTextAttributes = [.backgroundColor: textHighlightColor, .foregroundColor: style.barTextColor]
		}
		
		// Style content view
		let vibrant = ZGReadDefaultWindowVibrancy()
		do {
			contentView.state = vibrant ? .followsWindowActiveState : .inactive
			contentView.appearance = style.appearance
		}
		
		// Style scroll view
		do {
			scrollView.scrollerKnobStyle = style.scrollerKnobStyle
			if vibrant {
				scrollView.drawsBackground = false
			} else {
				scrollView.drawsBackground = true
				scrollView.backgroundColor = style.fallbackBackgroundColor
			}
		}
	}
	
	private func updateStyle(_ newStyle: ZGWindowStyle) {
		style = newStyle
		updateCurrentStyle()
	}
	
	private func commentUTF16Range(plainText: String) -> NSRange {
		let commentSectionIndex = plainText.index(plainText.endIndex, offsetBy: -commentSectionLength)
		
		return convertToUTF16Range(range: commentSectionIndex ..< plainText.endIndex, in: plainText)
	}
	
	private func removeBackgroundColors() {
		let plainText = currentPlainText()
		textView.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSMakeRange(0, plainText.endIndex.utf16Offset(in: plainText)))
		breadcrumbs?.textOverflowRanges.removeAllObjects()
	}
	
	private func updateFont(_ font: NSFont, utf16Range: NSRange) {
		textView.textStorage?.addAttribute(.font, value: font, range: utf16Range)
		
		// If we don't fix the font attributes, then attachments (like emoji) may become invisible and not show up
		textView.textStorage?.fixFontAttribute(in: utf16Range)
	}
	
	private func convertToUTF16Range(range: Range<String.Index>, in string: String) -> NSRange {
		let utf16LowerBound = range.lowerBound.utf16Offset(in: string)
		let utf16UpperBound = range.upperBound.utf16Offset(in: string)
		return NSMakeRange(utf16LowerBound, utf16UpperBound - utf16LowerBound)
	}
	
	private func updateTextProcessing() {
		let plainText = currentPlainText()
		
		func retrieveContentLineRanges() -> [Range<String.Index>] {
			let commentSectionIndex = plainText.index(plainText.endIndex, offsetBy: -commentSectionLength)
			
			var lineRanges: [Range<String.Index>] = []
			var characterIndex = plainText.startIndex
			while characterIndex < commentSectionIndex {
				var lineStartIndex = String.Index(utf16Offset: 0, in: plainText)
				var lineEndIndex = String.Index(utf16Offset: 0, in: plainText)
				var contentEndIndex = String.Index(utf16Offset: 0, in: plainText)
				
				plainText.getLineStart(&lineStartIndex, end: &lineEndIndex, contentsEnd: &contentEndIndex, for: characterIndex ..< characterIndex)
				
				let lineRange = (lineStartIndex ..< contentEndIndex)
				lineRanges.append(lineRange)
				
				characterIndex = lineEndIndex
			}
			return lineRanges
		}
		
		func updateHighlightOverflowing(lineRange: Range<String.Index>, limit: Int) {
			let distance = plainText.distance(from: lineRange.lowerBound, to: lineRange.upperBound)
			guard distance > limit else {
				return
			}
			
			let overflowRange = plainText.index(lineRange.lowerBound, offsetBy: limit) ..< lineRange.upperBound
			do {
				let utf16Range = convertToUTF16Range(range: overflowRange, in: plainText)
				
				textView.layoutManager?.addTemporaryAttribute(.backgroundColor, value: style.overflowColor, forCharacterRange: utf16Range)
			}
			
			if let breadcrumbs = breadcrumbs {
				breadcrumbs.textOverflowRanges.add(lineRange)
			}
		}
		
		func updateHighlighting(contentLineRanges: [Range<String.Index>], subjectLengthLimit: Int?, bodyLengthLimit: Int?) {
			guard subjectLengthLimit != nil || bodyLengthLimit != nil, contentLineRanges.count > 0 else {
				return
			}
			
			// Remove the attribute everywhere. Might be "inefficient" but it's the easiest most reliable approach I know how to do
			self.removeBackgroundColors()
			
			for contentLineRange in contentLineRanges {
				if contentLineRange.lowerBound == plainText.startIndex {
					if let subjectLengthLimit = subjectLengthLimit {
						let substring = String(plainText[contentLineRange.lowerBound ..< contentLineRange.upperBound])
						if !Self.isCommentLine(substring, versionControlType: commentVersionControlType) {
							updateHighlightOverflowing(lineRange: contentLineRange, limit: subjectLengthLimit)
						}
					}
					
					if bodyLengthLimit == nil {
						break
					}
				} else {
					assert(bodyLengthLimit != nil, "Body limit is nil but we should have breaked out earlier")
					if let bodyLengthLimit = bodyLengthLimit {
						let substring = String(plainText[contentLineRange.lowerBound ..< contentLineRange.upperBound])
						if !Self.isCommentLine(substring, versionControlType: commentVersionControlType) {
							updateHighlightOverflowing(lineRange: contentLineRange, limit: bodyLengthLimit)
						}
					}
				}
			}
		}
		
		func updateCommentAttributes(contentLineRanges: [Range<String.Index>]) {
			guard !Self.hasSingleCommentLineMarker(versionControlType: commentVersionControlType) else {
				return
			}
			
			let commentUTFRange = commentUTF16Range(plainText: currentPlainText())
			let contentUTFRange = NSMakeRange(0, commentUTFRange.location)
			
			// First assume all content has no comment lines
			updateFont(ZGReadDefaultMessageFont(), utf16Range: contentUTFRange)
			
			let textStorage = textView.textStorage
			
			var commentFont: NSFont? = nil
			for contentLineRange in contentLineRanges {
				let utf16LineRange = convertToUTF16Range(range: contentLineRange, in: plainText)
				
				if contentLineRange.upperBound > contentLineRange.lowerBound &&
					Self.isCommentLine(String(plainText[contentLineRange.lowerBound ..< contentLineRange.upperBound]), versionControlType: commentVersionControlType) {
					
					if let breadcrumbs = breadcrumbs {
						breadcrumbs.commentLineRanges.add(contentLineRange)
					}
					
					if let font = commentFont {
						updateFont(font, utf16Range: utf16LineRange)
					} else {
						let font = ZGReadDefaultCommentsFont()
						updateFont(font, utf16Range: utf16LineRange)
						commentFont = font
					}
				} else {
					textStorage?.removeAttribute(.foregroundColor, range: utf16LineRange)
				}
			}
		}
		
		func updateContentStyle(contentLineRanges: [Range<String.Index>]) {
			let textStorage = textView.textStorage
			
			for contentLineRange in contentLineRanges {
				let utf16LineRange = convertToUTF16Range(range: contentLineRange, in: plainText)
				
				if contentLineRange.upperBound > contentLineRange.lowerBound &&
					!Self.isCommentLine(String(plainText[contentLineRange.lowerBound ..< contentLineRange.upperBound]), versionControlType: commentVersionControlType) {
					textStorage?.removeAttribute(.foregroundColor, range: utf16LineRange)
					textStorage?.addAttribute(.foregroundColor, value: style.textColor, range: utf16LineRange)
				}
			}
		}
		
		let contentLineRanges = retrieveContentLineRanges()
		
		let subjectLengthLimit = ZGReadDefaultRecommendedSubjectLengthLimitEnabled() ? Int(ZGReadDefaultRecommendedSubjectLengthLimit()) : nil
		let bodyLengthLimit = ZGReadDefaultRecommendedBodyLineLengthLimitEnabled() ? Int(ZGReadDefaultRecommendedBodyLineLengthLimit()) : nil
		
		updateHighlighting(contentLineRanges: contentLineRanges, subjectLengthLimit: subjectLengthLimit, bodyLengthLimit: bodyLengthLimit)
		
		updateCommentAttributes(contentLineRanges: contentLineRanges)
		updateContentStyle(contentLineRanges: contentLineRanges)
		
		// Sometimes the insertion point isn't properly updated after updating
		// the comment attributes and content style.
		// Force an update to get around this issue.
		textView.updateInsertionPointStateAndRestartTimer(true)
	}
	
	private func updateEditorStyle(_ style: ZGWindowStyle) {
		updateStyle(style)
		updateTextProcessing()
		topBar.needsDisplay = true
		contentView.needsDisplay = true
		
		// The comment section isn't updated by setting the editor style elsewhere, since it's not editable.
		let commentRange = commentUTF16Range(plainText: currentPlainText())
		textView.textStorage?.removeAttribute(.foregroundColor, range: commentRange)
		textView.textStorage?.addAttribute(.foregroundColor, value: style.commentColor, range: commentRange)
	}
	
	private func updateEditorMessageFont() {
		let plainText = currentPlainText()
		let commentSectionIndex = plainText.index(plainText.endIndex, offsetBy: -commentSectionLength)
		
		updateFont(ZGReadDefaultMessageFont(), utf16Range: convertToUTF16Range(range: plainText.startIndex ..< commentSectionIndex, in: plainText))
	}
	
	private func updateEditorCommentsFont() {
		updateFont(ZGReadDefaultCommentsFont(), utf16Range: commentUTF16Range(plainText: currentPlainText()))
	}
	
	private func commitTextRange(plainText: String, commentLength: Int) -> Range<String.Index> {
		return plainText.startIndex ..< plainText.endIndex
	}
	
	@objc override func windowDidLoad() {
		self.window?.setFrameUsingName(ZGEditorWindowFrameNameKey)

		self.updateCurrentStyle()
		
		// Update style when user changes the system appearance
		self.effectiveAppearanceObserver = NSApp.observe(\.effectiveAppearance, changeHandler: { [weak self] (application, change) in
			guard let self = self else {
				return
			}
			
			if change.oldValue?.name != change.newValue?.name {
				let defaultTheme = ZGReadDefaultWindowStyleTheme()
				let theme = Self.styleTheme(defaultTheme: defaultTheme, effectiveAppearance: application.effectiveAppearance)
				
				self.updateEditorStyle(ZGWindowStyle(theme: theme))
			}
		})
		
		commitLabelTextField.stringValue = projectNameDisplay
		
		// Give a little vertical padding between the text and the top of the text view container
		let textContainerInset = textView.textContainerInset
		textView.textContainerInset = NSMakeSize(textContainerInset.width, textContainerInset.height + 2)
		
		if let window = window {
			window.titlebarAppearsTransparent = true
			
			// Hide the window titlebar buttons
			// We still want the resize functionality to work even though the button is hidden
			window.standardWindowButton(.closeButton)?.isHidden = true
			window.standardWindowButton(.miniaturizeButton)?.isHidden = true
			window.standardWindowButton(.zoomButton)?.isHidden = true
		}
		
		// Nobody ever wants these;
		// Because macOS may have some of these settings globally in System Preferences, I don't trust IB very much..
		textView.isAutomaticDashSubstitutionEnabled = false
		textView.isAutomaticQuoteSubstitutionEnabled = false
		
		// Set textview delegates
		textView.textStorage?.delegate = self
		textView.layoutManager?.delegate = self
		textView.delegate = self
		textView.zgCommitViewDelegate = self
		
		// If this is a squash, just turn off spell checking and automatic spell correction as it's more likely to annoy the user
		if isSquashMessage && ZGReadDefaultDisableSpellCheckingAndCorrectionForSquashes() {
			textView.zgDisableContinuousSpellingAndAutomaticSpellingCorrection()
		} else {
			textView.zgLoadDefaults()
		}
		
		if let breadcrumbs = breadcrumbs {
			breadcrumbs.spellChecking = textView.isContinuousSpellCheckingEnabled
		}
		
		// Set comment section attributes
		let plainAttributedString = NSMutableAttributedString(string: initialPlainText)
		if commentSectionLength != 0 {
			plainAttributedString.addAttribute(.foregroundColor, value: style.commentColor, range: commentUTF16Range(plainText: initialPlainText))
		}
		
		// I don't think we want to invoke beginEditing/endEditing, etc, events because we are setting the textview content for the first time,
		// and we don't want anything to register as user-editable yet or have undo activated yet
		textView.textStorage?.replaceCharacters(in: NSMakeRange(0, 0), with: plainAttributedString)
		
		updateTextViewDrawingBackground()
		
		updateEditorMessageFont()
		updateEditorCommentsFont()
		
		// Necessary to update text processing otherwise colors may not be right
		updateTextProcessing()
		
		// If we're resuming a canceled commit message, select all the contents
		// Otherwise point the selection at the end of the message contents
		let commitRange = commitTextRange(plainText: initialPlainText, commentLength: commentSectionLength)
		if resumedFromSavedCommit {
			textView.setSelectedRange(convertToUTF16Range(range: commitRange, in: initialPlainText))
		} else {
			textView.setSelectedRange(convertToUTF16Range(range: commitRange.upperBound ..< commitRange.upperBound, in: initialPlainText))
		}
		
		func showBranchName() {
			let toolName: String
			let toolArguments: [String]
			
			switch versionControlType {
			case .git:
				toolName = "git"
				toolArguments = ["rev-parse", "--symbolic-full-name", "--abbrev-ref", "HEAD"]
			case .hg:
				toolName = "hg"
				toolArguments = ["branch"]
			case .svn:
				return
			}
			
			if let toolURL = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":").map({ parentDirectoryPath -> URL in
				return URL(fileURLWithPath: parentDirectoryPath).appendingPathComponent(toolName)
			}).first(where: { toolURL -> Bool in
				let reachable = try? toolURL.checkResourceIsReachable()
				return reachable ?? false
			}) {
				DispatchQueue.global(qos: .userInteractive).async {
					let process = Process()
					process.executableURL = toolURL
					process.arguments = toolArguments
					
					let pipe = Pipe()
					process.standardOutput = pipe
					
					do {
						try process.run()
						process.waitUntilExit()
						
						if process.terminationStatus == EXIT_SUCCESS {
							let data = pipe.fileHandleForReading.readDataToEndOfFile()
							if let branchName = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), branchName.count > 0 {
								DispatchQueue.main.async {
									let projectNameWithBranch = "\(self.projectNameDisplay) \(branchName)"
									self.commitLabelTextField.stringValue = projectNameWithBranch
								}
							}
						}
					} catch {
						print("Failed to retrieve branch name: \(error)")
					}
				}
			}
		}
		
		// Show branch name if available
		if !tutorialMode {
			showBranchName()
		}
	}
	
	func exit(withSuccess success: Bool) {
		//...
	}
	
	@IBAction @objc func commit(_ sender: AnyObject) {
		
	}
	
	@IBAction @objc func cancelCommit(_ sender: AnyObject) {
		
	}
	
	// MARK: ZGCommitViewDelegate
	
	func userDefaultsChangedMessageFont() {
		
	}
	
	func userDefaultsChangedCommentsFont() {
		
	}
	
	func userDefaultsChangedRecommendedLineLengthLimits() {
		
	}
	
	func zgCommitViewSelectAll() {
		
	}
	
	func zgCommitViewTouchCommit(_ sender: Any) {
		
	}
	
	func zgCommitViewTouchCancel(_ sender: Any) {
		
	}
}
