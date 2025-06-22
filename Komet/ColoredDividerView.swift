//
//  ColoredDividerView.swift
//  Komet
//
//  Created by Mayur Pawashe on 6/21/25.
//  Copyright © 2025 zgcoder. All rights reserved.
//

import Foundation
import AppKit

// Simple view at 1 height that draws a background fill color
class ColoredDivider: NSView {
	var fillColor: NSColor = .gray {
		didSet {
			needsDisplay = true
		}
	}
	
	override var intrinsicContentSize: NSSize {
		return NSSize(width: NSView.noIntrinsicMetric, height: 1)
	}
	
	override func draw(_ dirtyRect: NSRect) {
		fillColor.setFill()
		bounds.fill()
	}
}
