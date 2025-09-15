//
//  ContentViewController.swift
//  Komet
//
//  Created by Mayur Pawashe on 6/19/25.
//  Copyright © 2025 zgcoder. All rights reserved.
//

import Cocoa

class ContentViewController: NSViewController, NSTextStorageDelegate, NSTextContentStorageDelegate, ZGCommitViewDelegate, NSTextViewDelegate {
	@IBOutlet private var scrollViewContainer: NSView!
	
	private var textView: ZGCommitTextView!
	private var scrollView: NSScrollView!
	
	private let initialPlainText: String
	private let commentSectionLength: Int
	private let commentVersionControlType: VersionControlType
	private let resumedFromSavedCommit: Bool
	private let initialCommitTextRange: Range<String.UTF16View.Index>
	private let isSquashMessage: Bool
	private let versionControlledFile: Bool
	
	private var preventAccidentalNewline: Bool = false
	
	var breadcrumbs: Breadcrumbs?
	
	var commitHandler: (() -> ())? = nil
	var cancelHandler: (() -> ())? = nil
	
	init(initialPlainText: String, commentSectionLength: Int, commentVersionControlType: VersionControlType, resumedFromSavedCommit: Bool, initialCommitTextRange: Range<String.UTF16View.Index>, isSquashMessage: Bool, versionControlledFile: Bool, breadcrumbs: Breadcrumbs?) {
		self.initialPlainText = initialPlainText
		self.commentSectionLength = commentSectionLength
		self.commentVersionControlType = commentVersionControlType
		self.resumedFromSavedCommit = resumedFromSavedCommit
		self.initialCommitTextRange = initialCommitTextRange
		self.isSquashMessage = isSquashMessage
		self.versionControlledFile = versionControlledFile
		self.breadcrumbs = breadcrumbs
		
		super.init(nibName: "Content", bundle: Bundle.main)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private static func lengthLimitWarningEnabled(userDefaults: UserDefaults, userDefaultKey: String, versionControlledFile: Bool) -> Bool {
		return versionControlledFile && userDefaults.bool(forKey: userDefaultKey)
	}
	
	var style: WindowStyle? {
		didSet {
			guard let style else {
				return
			}
			
			// Style text
			do {
				textView.wantsLayer = true
				updateTextViewDrawingBackground()
				textView.insertionPointColor = style.textColor
				
				// As fallback, use NSColor.selectedControlColor. Note NSColor.selectedTextColor does not give right results.
				let textHighlightColor = style.textHighlightColor ?? NSColor.selectedControlColor
				textView.selectedTextAttributes = [.backgroundColor: textHighlightColor, .foregroundColor: style.barTextColor]
				
				if #unavailable(macOS 13) {
					if let window = view.window, window.isVisible {
						// Changing NSTextView selection color doesn't quite work correctly when using TextKit2 by itself
						// So we apply an additional workaround to get NSTextView to update the selection text color for real
						// Unfortunately we will need to deselect any selected text ranges as well
						// Workaround found here: https://github.com/ChimeHQ/TextViewPlus
						// Filed FB9967570. Note this is fixed in macOS 13 and later.
						
						let selectedTextRange = textView.selectedRange()
						if selectedTextRange.length > 0 {
							textView.setSelectedRange(NSMakeRange(selectedTextRange.location, 0))
						}
						
						textView.rotate(byDegrees: 1.0)
						textView.rotate(byDegrees: -1.0)
					}
				}
			}
			
			// Style content view
			let vibrant = UserDefaults.standard.bool(forKey: ZGWindowVibrancyKey)
			
			if let visualEffectView = view as? NSVisualEffectView {
				visualEffectView.state = vibrant ? .followsWindowActiveState : .inactive
				visualEffectView.appearance = style.appearance
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
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Following these steps to set up scroll view and text view
		// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html#//apple_ref/doc/uid/20000938-CJBBIAAF
		scrollView = NSScrollView(frame: scrollViewContainer.frame)
		scrollView.borderType = .noBorder
		scrollView.hasVerticalScroller = true
		scrollView.hasHorizontalScroller = false
		scrollView.autoresizingMask = .init(rawValue: NSView.AutoresizingMask.width.rawValue | NSView.AutoresizingMask.height.rawValue)
		
		let scrollViewContentSize = scrollView.contentSize
		let textContainerSize = NSMakeSize(scrollViewContentSize.width, CGFloat(Float.greatestFiniteMagnitude))
		
		// Initialize NSTextView via code snippets from https://developer.apple.com/documentation/appkit/nstextview/1449347-initwithframe
		do {
			let textLayoutManager = NSTextLayoutManager()
			
			let textContainer = NSTextContainer(size: textContainerSize)
			textLayoutManager.textContainer = textContainer
			
			let textContentStorage = NSTextContentStorage()
			textContentStorage.addTextLayoutManager(textLayoutManager)
			textContentStorage.delegate = self
			
			textView = ZGCommitTextView(frame: NSMakeRect(0.0, 0.0, scrollViewContentSize.width, scrollViewContentSize.height), textContainer: textLayoutManager.textContainer)
			
#if DEBUG
			NotificationCenter.default.addObserver(forName: NSTextView.didSwitchToNSLayoutManagerNotification, object: textView, queue: OperationQueue.main) { _ in
				
				assertionFailure("TextView should not be switching to TextKit 1 layout manager")
			}
#endif
		}
		
		textView.minSize = NSMakeSize(0.0, scrollViewContentSize.height)
		textView.maxSize = NSMakeSize(CGFloat(Float.greatestFiniteMagnitude), CGFloat(Float.greatestFiniteMagnitude))
		textView.isVerticallyResizable = true
		textView.isHorizontallyResizable = false
		textView.autoresizingMask = .width
		textView.textContainer?.widthTracksTextView = true
		textView.allowsUndo = true
		textView.isRichText = false
		textView.usesRuler = false
		textView.usesFindBar = true
		textView.isIncrementalSearchingEnabled = false
		textView.isAutomaticDataDetectionEnabled = false
		// Keeping the font panel enabled can lead to a serious performance hit:
		// https://christiantietze.de/posts/2021/09/nstextview-fontpanel-slowness/
		// We don't want to use it anyway
		textView.usesFontPanel = false
		
		scrollView.documentView = textView
		scrollViewContainer.addSubview(scrollView)
		
		// Give a little vertical padding between the text and the top of the text view container
		let textContainerInset = textView.textContainerInset
		textView.textContainerInset = NSMakeSize(textContainerInset.width, textContainerInset.height + 2)
		
		// Nobody ever wants these;
		// Because macOS may have some of these settings globally in System Preferences, I don't trust IB very much..
		textView.isAutomaticDashSubstitutionEnabled = false
		textView.isAutomaticQuoteSubstitutionEnabled = false
		
		// Set textview delegates
		textView.textStorage?.delegate = self
		
		textView.delegate = self
		textView.zgCommitViewDelegate = self
		
		let plainAttributedString = NSMutableAttributedString(string: initialPlainText)
		
		// I don't think we want to invoke beginEditing/endEditing, etc, events because we are setting the textview content for the first time,
		// and we don't want anything to register as user-editable yet or have undo activated yet
		textView.textStorage?.replaceCharacters(in: NSMakeRange(0, 0), with: plainAttributedString)
		
		updateTextViewDrawingBackground()
		
		// If we have a non-version controlled file, point selection at start of content
		// Otherwise if we're resuming a canceled commit message, select all the contents
		// Otherwise point the selection at the end of the message contents
		if !versionControlledFile {
			textView.setSelectedRange(NSMakeRange(0, 0))
		} else {
			if resumedFromSavedCommit {
				textView.setSelectedRange(TextProcessor.convertToUTF16Range(range: initialCommitTextRange, in: initialPlainText))
			} else {
				textView.setSelectedRange(TextProcessor.convertToUTF16Range(range: initialCommitTextRange.upperBound ..< initialCommitTextRange.upperBound, in: initialPlainText))
			}
		}
		
		// If this is a squash or non-version controlled file, just turn off spell checking and automatic spell correction as it's more likely to annoy the user
		// Make sure to disable this after setting the text storage content because spell checking detection
		// depends on that being initially set
		let userDefaults = UserDefaults.standard
		if (isSquashMessage || !versionControlledFile) && userDefaults.bool(forKey: ZGDisableSpellCheckingAndCorrectionForSquashesKey) {
			textView.zgDisableContinuousSpellingAndAutomaticSpellingCorrection()
		} else {
			textView.zgLoadDefaults()
		}
		
		breadcrumbs?.spellChecking = textView.isContinuousSpellCheckingEnabled
    }
	
	private func updateTextViewDrawingBackground() {
		textView.drawsBackground = false
	}
	
	func reloadTextAttributes() {
		// Replacing all the characters will force all the text attributes to be re-computed
		// I wonder if there is a better way of doing this
		if let textStorage = textView.textStorage, let attributedCopy = textStorage.copy() as? NSAttributedString {
			textStorage.setAttributedString(attributedCopy)
		}
	}
    
	func currentPlainText() -> String {
		let textStorage = textView.textStorage
		return textStorage?.string ?? ""
	}
	
	func commitMessageContent() -> String {
		let plainText = currentPlainText()
		let commitRange = TextProcessor.commitTextRange(plainText: plainText, commentLength: commentSectionLength)
		
		let content = plainText[commitRange.lowerBound ..< commitRange.upperBound]
		return content.trimmingCharacters(in: .newlines)
	}
	
	func zgCommitViewSelectAll() {
		let plainText = currentPlainText()
		if commentSectionLength > 0 {
			// Select only the commit text range
			let commitRange = TextProcessor.commitTextRange(plainText: plainText, commentLength: commentSectionLength)
			textView.setSelectedRange(TextProcessor.convertToUTF16Range(range: commitRange, in: plainText))
		} else {
			// Select everything
			textView.setSelectedRange(NSMakeRange(0, plainText.utf16.count))
		}
	}
	
	@objc func zgCommitViewTouchCommit(_ sender: Any) {
		commitHandler?()
	}
	
	@objc func zgCommitViewTouchCancel(_ sender: Any) {
		cancelHandler?()
	}
	
	func updateBreadcrumbsIfNeeded() {
		guard breadcrumbs != nil else {
			return
		}
		
		func retrieveLineRanges(plainText: String) -> [Range<String.Index>] {
			var lineRanges: [Range<String.Index>] = []
			var characterIndex = plainText.startIndex
			while characterIndex < plainText.endIndex {
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
		
		if let textContentStorage = textView.textContentStorage {
			let currentText = currentPlainText()
			let contentLineRanges = retrieveLineRanges(plainText: currentText)
			
			for contentLineRange in contentLineRanges {
				let utf16Range = TextProcessor.convertToUTF16Range(range: contentLineRange, in: currentText)
				let _ = newTextParagraph(textContentStorage, range: utf16Range, updateBreadcrumbs: true)
			}
		}
	}
	
	// MARK: Text View Delegates
	
	@objc func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
		let commentRange = TextProcessor.commentUTF16Range(plainText: currentPlainText(), commentSectionLength: commentSectionLength)
		
		// Don't allow editing the comment section
		// Make sure to also check we have a comment section, otherwise we would be
		// not allowing to insert text at the end of the document for no reason
		if commentRange.length > 0 {
			for rangeValue in affectedRanges {
				let range = rangeValue.rangeValue
				if range.location + range.length >= commentRange.location {
					return false
				}
			}
		}
		
		return true
	}
	
	private func newTextParagraph(_ textContentStorage: NSTextContentStorage, range: NSRange, updateBreadcrumbs: Bool) -> NSTextParagraph? {
		guard let originalText = textContentStorage.textStorage?.attributedSubstring(from: range) else {
			return nil
		}
		
		guard let style else {
			assert(false)
			return nil
		}
		
		let originalTextString = originalText.string
		
		let commentRange: NSRange
		do {
			let plainText = currentPlainText()
			commentRange = TextProcessor.commentUTF16Range(plainText: plainText, commentSectionLength: commentSectionLength)
		}
		
		let paragraphWithDisplayAttributes: NSTextParagraph?
		let isCommentSection = (range.location >= commentRange.location)
		let isCommentLine = TextProcessor.isCommentLine(originalTextString, versionControlType: commentVersionControlType)
		let hasSingleCommentLineMarker = TextProcessor.hasSingleCommentLineMarker(versionControlType: commentVersionControlType)
		// For svn we want to test isCommentSection
		// For git, we want to test isCommentLine. Scissored content may be in the comment section but
		// we don't want to format those lines as comments
		let isCommentParagraph = isCommentLine || (hasSingleCommentLineMarker && isCommentSection)

		let userDefaults = UserDefaults.standard
		
		if !isCommentParagraph {
			let contentFont = ZGReadDefaultFont(userDefaults, ZGMessageFontNameKey, ZGMessageFontPointSizeKey)
			
			let displayAttributes: [NSAttributedString.Key: AnyObject] = [.font: contentFont, .foregroundColor: style.textColor]
			
			let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
			
			let fullTextRange = NSMakeRange(0, range.length)
			textWithDisplayAttributes.addAttributes(displayAttributes, range: fullTextRange)
			
			if versionControlledFile {
				let handleScissoredLineDiffing: Bool
				switch commentVersionControlType {
				case .jj:
					fallthrough
				case .git:
					handleScissoredLineDiffing = true
				case .svn:
					fallthrough
				case .hg:
					handleScissoredLineDiffing = false
				}
				
				if handleScissoredLineDiffing && isCommentSection {
					// Handle highlighting diffs
					
					let diffAttributeKey = style.diffHighlightsBackground ? NSAttributedString.Key.backgroundColor : NSAttributedString.Key.foregroundColor
					
					let diffAttributeColor: NSColor?
					
					// https://git-scm.com/docs/git-diff-index documents the possible header line prefixes
					if originalTextString.hasPrefix("@@") ||
						originalTextString.hasPrefix("+++") ||
						originalTextString.hasPrefix("---") ||
						originalTextString.hasPrefix("diff ") ||
						(originalTextString.hasPrefix("index ") && originalTextString.contains("..")) ||
						originalTextString.hasPrefix("deleted file mode") ||
						originalTextString.hasPrefix("new file mode") ||
						originalTextString.hasPrefix("copy from") ||
						originalTextString.hasPrefix("copy to") ||
						originalTextString.hasPrefix("rename from") ||
						originalTextString.hasPrefix("rename to") ||
						originalTextString.hasPrefix("similarity index") ||
						originalTextString.hasPrefix("dissimilarity index") ||
						originalTextString.hasPrefix("old mode") ||
						originalTextString.hasPrefix("new mode") {
						diffAttributeColor = style.diffHeaderColor
						
						if updateBreadcrumbs && breadcrumbs != nil {
							breadcrumbs!.diffHeaderLineRanges.append(fullTextRange.location ..< NSMaxRange(fullTextRange))
						}
					} else if originalTextString.hasPrefix("+") {
						diffAttributeColor = style.diffAddColor
						
						if updateBreadcrumbs && breadcrumbs != nil {
							breadcrumbs!.diffAddLineRanges.append(fullTextRange.location ..< NSMaxRange(fullTextRange))
						}
					} else if originalTextString.hasPrefix("-") {
						diffAttributeColor = style.diffRemoveColor
						
						if updateBreadcrumbs && breadcrumbs != nil {
							breadcrumbs!.diffRemoveLineRanges.append(fullTextRange.location ..< NSMaxRange(fullTextRange))
						}
					} else {
						diffAttributeColor = nil
					}
					
					if let diffAttributeColor {
						let diffAttributes: [NSAttributedString.Key : AnyObject] = [.font: contentFont, diffAttributeKey: diffAttributeColor]
						
						textWithDisplayAttributes.addAttributes(diffAttributes, range: fullTextRange)
					}
				} else if !isSquashMessage {
					// Render text overflow highlights
					
					let lengthLimit: Int?
					if range.location == 0 {
						lengthLimit = Self.lengthLimitWarningEnabled(userDefaults: userDefaults, userDefaultKey: ZGEditorRecommendedSubjectLengthLimitEnabledKey, versionControlledFile: versionControlledFile) ? ZGReadDefaultLineLimit(userDefaults, ZGEditorRecommendedSubjectLengthLimitKey) : nil
					} else {
						lengthLimit = Self.lengthLimitWarningEnabled(userDefaults: userDefaults, userDefaultKey: ZGEditorRecommendedBodyLineLengthLimitEnabledKey, versionControlledFile: versionControlledFile) ? ZGReadDefaultLineLimit(userDefaults, ZGEditorRecommendedBodyLineLengthLimitKey) : nil
					}
					
					if let lengthLimit = lengthLimit {
						let distance = originalTextString.distance(from: originalTextString.startIndex, to: originalTextString.endIndex)
						
						if distance > lengthLimit {
							let overflowRange = originalTextString.index(originalTextString.startIndex, offsetBy: lengthLimit) ..< originalTextString.endIndex
							
							let overflowUtf16Range = TextProcessor.convertToUTF16Range(range: overflowRange, in: originalTextString)
							
							let overflowAttributes: [NSAttributedString.Key: AnyObject] = [.font: contentFont, .backgroundColor: style.overflowColor]
							
							textWithDisplayAttributes.addAttributes(overflowAttributes, range: overflowUtf16Range)
							
							if updateBreadcrumbs && breadcrumbs != nil {
								breadcrumbs!.textOverflowRanges.append(range.location + overflowUtf16Range.location ..< range.location + NSMaxRange(overflowUtf16Range))
							}
						}
					}
				}
			}
			
			paragraphWithDisplayAttributes = NSTextParagraph(attributedString: textWithDisplayAttributes)
		} else {
			let commentFont = ZGReadDefaultFont(userDefaults, ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey)
			
			var commentChangeColorAndCommentPrefixLength: (NSColor, Int)? = nil
			if isCommentSection && versionControlledFile && UserDefaults.standard.bool(forKey: ZGHighlightFileChangesKey) {
				if #available(macOS 13, *) {
					if let (label, commentPrefixLength) = TextProcessor.labelInCommentLine(originalText.string, versionControlType: commentVersionControlType) {
						switch commentVersionControlType {
						case .git:
							switch label {
							case "renamed": fallthrough
							case "copied": fallthrough
							case "modified":
								commentChangeColorAndCommentPrefixLength = (style.changeModifiedColor, commentPrefixLength)
							case "new file":
								commentChangeColorAndCommentPrefixLength = (style.changeAddedColor, commentPrefixLength)
							case "deleted":
								commentChangeColorAndCommentPrefixLength = (style.changeDeletedColor, commentPrefixLength)
							default:
								break
							}
						case .jj:
							switch label {
							case "R": fallthrough
							case "C": fallthrough
							case "M":
								commentChangeColorAndCommentPrefixLength = (style.changeModifiedColor, commentPrefixLength)
							case "A":
								commentChangeColorAndCommentPrefixLength = (style.changeAddedColor, commentPrefixLength)
							case "D":
								commentChangeColorAndCommentPrefixLength = (style.changeDeletedColor, commentPrefixLength)
							default:
								break
							}
						case .hg:
							switch label {
							case "changed":
								commentChangeColorAndCommentPrefixLength = (style.changeModifiedColor, commentPrefixLength)
							case "added":
								commentChangeColorAndCommentPrefixLength = (style.changeAddedColor, commentPrefixLength)
							case "removed":
								commentChangeColorAndCommentPrefixLength = (style.changeDeletedColor, commentPrefixLength)
							default:
								break
							}
						case .svn:
							// Not testing svn
							break
						}
					}
				}
			}
			
			let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
			
			if let (commentChangeColor, commentPrefixLength) = commentChangeColorAndCommentPrefixLength {
				do {
					let displayAttributes: [NSAttributedString.Key: AnyObject] = [.font: commentFont, .foregroundColor: style.commentColor]
					textWithDisplayAttributes.addAttributes(displayAttributes, range: NSMakeRange(0, commentPrefixLength))
				}
				
				if range.length > commentPrefixLength {
					let displayAttributes: [NSAttributedString.Key: AnyObject] = [.font: commentFont, .foregroundColor: commentChangeColor]
					textWithDisplayAttributes.addAttributes(displayAttributes, range: NSMakeRange(commentPrefixLength, range.length - commentPrefixLength))
				}
			} else {
				let displayAttributes: [NSAttributedString.Key: AnyObject] = [.font: commentFont, .foregroundColor: style.commentColor]
				textWithDisplayAttributes.addAttributes(displayAttributes, range: NSMakeRange(0, range.length))
			}
			
			if updateBreadcrumbs && !isCommentSection && breadcrumbs != nil {
				breadcrumbs!.commentLineRanges.append(range.location ..< NSMaxRange(range))
			}
			
			paragraphWithDisplayAttributes = NSTextParagraph(attributedString: textWithDisplayAttributes)
		}
		
		return paragraphWithDisplayAttributes
	}
	
	func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
		return newTextParagraph(textContentStorage, range: range, updateBreadcrumbs: false)
	}
	
	@objc func textView(_ textView: NSTextView, shouldSetSpellingState value: Int, range affectedCharRange: NSRange) -> Int {
		let plainText = currentPlainText()
		
		let commentRange = TextProcessor.commentUTF16Range(plainText: plainText, commentSectionLength: commentSectionLength)
		
		// Check if affected character range is in the comment section (which includes scissored content)
		if affectedCharRange.location >= commentRange.location {
			return 0
		}
		
		guard let affectedRange = Range(affectedCharRange, in: plainText) else {
			return value
		}
		
		var lineStartIndex = String.Index(utf16Offset: 0, in: plainText)
		var lineEndIndex = String.Index(utf16Offset: 0, in: plainText)
		var contentEndIndex = String.Index(utf16Offset: 0, in: plainText)
		
		plainText.getLineStart(&lineStartIndex, end: &lineEndIndex, contentsEnd: &contentEndIndex, for: affectedRange)
		let line = String(plainText[lineStartIndex ..< contentEndIndex])
		
		return TextProcessor.isCommentLine(line, versionControlType: commentVersionControlType) ? 0 : value
	}
	
	@objc func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		// After the user enters a new line in the first line, we want to insert another newline due to commit'ing conventions
		
		guard commandSelector == #selector(insertNewline(_:)) else {
			return false
		}
		
		// Bail if automatic newline insertion is disabled or if we are dealing with a squash message
		let userDefaults = UserDefaults.standard
		guard versionControlledFile && userDefaults.bool(forKey: ZGEditorAutomaticNewlineInsertionAfterSubjectKey) && (!userDefaults.bool(forKey: ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashesKey) || !isSquashMessage) else {
			return false
		}
		
		// We will have some prevention if the user performs a new line more than once consecutively
		guard !preventAccidentalNewline else {
			return true
		}
		
		let selectedUTF16Ranges = textView.selectedRanges.map({ $0.rangeValue })
		guard selectedUTF16Ranges.count == 1 else {
			return false
		}
		
		let utf16Range = selectedUTF16Ranges[0]
		
		do {
			let plainText = currentPlainText()
			guard let range = Range(utf16Range, in: plainText) else {
				return false
			}
			
			guard let startContentLineIndex = TextProcessor.firstContentLineIndex(plainText: plainText, versionControlType: commentVersionControlType) else {
				return false
			}
			
			var lineStartIndex = String.Index(utf16Offset: 0, in: plainText)
			var lineEndIndex = String.Index(utf16Offset: 0, in: plainText)
			var contentEndIndex = String.Index(utf16Offset: 0, in: plainText)
			
			plainText.getLineStart(&lineStartIndex, end: &lineEndIndex, contentsEnd: &contentEndIndex, for: range)
			
			// We must be at the first (subject) line and there must be some content
			guard lineStartIndex == startContentLineIndex, contentEndIndex > lineStartIndex else {
				return false
			}
			
			// Line must be at beginning of comment section or must be newline character
			let utf16View = plainText.utf16
			guard lineEndIndex == TextProcessor.commentSectionIndex(plainUTF16Text: utf16View, commentSectionLength: commentSectionLength) || plainText[lineEndIndex].isNewline else {
				return false
			}
		}
		
		let replacement = "\n\n"
		guard textView.shouldChangeText(in: utf16Range, replacementString: replacement), let textStorage = textView.textStorage else {
			return false
		}
		
		// We need to invoke these methods to get proper undo support
		// http://lists.apple.com/archives/cocoa-dev/2004/Jan/msg01925.html
		
		textStorage.beginEditing()
		
		textStorage.replaceCharacters(in: utf16Range, with: replacement)
		
		textStorage.endEditing()
		textView.didChangeText()
		
		preventAccidentalNewline = true
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.preventAccidentalNewline = false
		}
		
		return true
	}
}
