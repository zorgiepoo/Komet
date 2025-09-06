//
//  TextProcessor.swift
//  Komet
//
//  Created by Mayur Pawashe on 6/21/25.
//  Copyright © 2025 zgcoder. All rights reserved.
//

import Foundation

enum VersionControlType {
	case git
	case hg
	case svn
	case jj
}

struct TextProcessor {
	static func isCommentLine(_ line: String, versionControlType: VersionControlType) -> Bool {
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
		case .jj:
			prefix = "JJ:"
			suffix = ""
		}
		
		// Note a line that is "--" could have the prefix and suffix the same, but we want to make sure it's at least "--...--" length long
		return line.hasPrefix(prefix) && line.hasSuffix(suffix) && line.count >= prefix.count + suffix.count
	}

	static func isScissorLine(_ line: String, versionControlType: VersionControlType) -> Bool {
		switch versionControlType {
		case .git:
			return line.hasPrefix("# --") && line.hasSuffix("--") && line.contains(">8")
		case .hg:
			return false
		case .svn:
			return false
		case .jj:
			return line == "JJ: ignore-rest"
		}
	}

	static func hasSingleCommentLineMarker(versionControlType: VersionControlType) -> Bool {
		switch versionControlType {
		case .git:
			return false
		case .hg:
			return false
		case .svn:
			return true
		case .jj:
			return false
		}
	}

	// The comment range should begin at the line that starts with a comment string and extend to the end of the file.
	// Additionally, there should be no content lines (i.e, non comment lines) within this section
	// (exception: unless we're dealing with svn which only has a starting point for comments)
	// This should only be computed once, before the user gets a chance to edit the content
	static func commentSectionLength(plainText: String, versionControlType: VersionControlType) -> Int {
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
			
			if !commentLine && foundCommentSection && (lineEndIndex != plainTextEndIndex || line.trimmingCharacters(in: .whitespacesAndNewlines).count > 0) {
				// If we found a non-comment line, then we have to find a better starting point for the comment section
				// If an empty line is at the end of the file and we've found a comment section, it's not too interesting
				foundCommentSection = false
			} else if commentLine {
				if !foundCommentSection {
					foundCommentSection = true
					commentSectionCharacterIndex = characterIndex
					
					// If there's only a single comment line marker, then we're done
					if hasSingleCommentLineMarker(versionControlType: versionControlType) {
						break
					}
				} else if isScissorLine(line, versionControlType: versionControlType) {
					// Everything below the scissor line is non-editable content which will be part of the comment section
					// Content bellow the scissor line may include lines that show a diff of a commit message and aren't prefixed by a comment character
					break
				}
			}
			
			characterIndex = lineEndIndex
		}
		
		return foundCommentSection ? (plainText.utf16.count - commentSectionCharacterIndex.utf16Offset(in: plainText)) : 0
	}
	
	// Find the first commit line. The first lines may be comment lines, which
	// we'll need to skip
	static func firstContentLineIndex(plainText: String, versionControlType: VersionControlType) -> String.Index? {
		let plainTextEndIndex = plainText.endIndex
		var characterIndex = String.Index(utf16Offset: 0, in: plainText)
		var lineStartIndex = String.Index(utf16Offset: 0, in: plainText)
		var lineEndIndex = String.Index(utf16Offset: 0, in: plainText)
		var contentEndIndex = String.Index(utf16Offset: 0, in: plainText)
		
		while characterIndex < plainTextEndIndex {
			plainText.getLineStart(&lineStartIndex, end: &lineEndIndex, contentsEnd: &contentEndIndex, for: characterIndex ..< characterIndex)
			
			let line = String(plainText[lineStartIndex ..< contentEndIndex])
			guard isCommentLine(line, versionControlType: versionControlType) else {
				return lineStartIndex
			}
			
			characterIndex = lineEndIndex
		}
		
		return nil
	}

	// The content range should extend to before the comments, only allowing one trailing newline in between the comments and content
	// Make sure to scan from the bottom to top
	static func commitTextRange(plainText: String, commentLength: Int) -> Range<String.UTF16View.Index> {
		let utf16View = plainText.utf16
		var bestEndCharacterIndex = utf16View.index(utf16View.endIndex, offsetBy: -commentLength)
		
		var passedNewline = false
		
		let startIndex = utf16View.startIndex
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

		return startIndex ..< bestEndCharacterIndex
	}

	static func convertToUTF16Range(range: Range<String.Index>, in string: String) -> NSRange {
		return NSRange(range, in: string)
	}
	
	static func commentSectionIndex(plainUTF16Text: String.UTF16View, commentSectionLength: Int) -> String.UTF16View.Index {
		return plainUTF16Text.index(plainUTF16Text.endIndex, offsetBy: -commentSectionLength)
	}
	
	static func commentUTF16Range(plainText: String, commentSectionLength: Int) -> NSRange {
		let utf16View = plainText.utf16
		return Self.convertToUTF16Range(range: commentSectionIndex(plainUTF16Text: utf16View, commentSectionLength: commentSectionLength) ..< utf16View.endIndex, in: plainText)
	}
}
