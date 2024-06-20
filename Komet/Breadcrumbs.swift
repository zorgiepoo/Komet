//
//  Breadcrumbs.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/25/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Foundation

typealias UTF16Offset = Int

struct Breadcrumbs: Codable {
	var textOverflowRanges: Array<Range<UTF16Offset>> = []
	var commentLineRanges: Array<Range<UTF16Offset>> = []
	var diffHeaderLineRanges: Array<Range<UTF16Offset>> = []
	var diffAddLineRanges: Array<Range<UTF16Offset>> = []
	var diffRemoveLineRanges: Array<Range<UTF16Offset>> = []
	var exitStatus: Int32 = 0
	var spellChecking: Bool = false
}
