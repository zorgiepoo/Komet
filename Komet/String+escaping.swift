//
//  String+escaping.swift
//  Komet
//
//  Created by Nathan Manceaux-Panot on 2025-03-08.
//  Copyright © 2025 zgcoder. All rights reserved.
//

import Foundation

fileprivate let singleQuote = "'"
fileprivate let doubleQuote = "\""
fileprivate let antiSlash = "\\"

extension String {
	var escapingGitConfigBreakingCharacters: String {
		self
			.replacingOccurrences(of: antiSlash, with: antiSlash + antiSlash)
			.replacingOccurrences(of: singleQuote, with: antiSlash + singleQuote)
			.replacingOccurrences(of: doubleQuote, with: antiSlash + doubleQuote)
			.replacingOccurrences(of: " ", with: antiSlash + " ")
	}
	
	var doubleQuoteDelimited: String {
		doubleQuote
		+ self
			.replacingOccurrences(of: antiSlash, with: antiSlash + antiSlash)
			.replacingOccurrences(of: doubleQuote, with: antiSlash + doubleQuote)
		+ doubleQuote
	}
}
