//
//  WindowStyle.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/1/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Cocoa

struct WindowStyle {
	let barColor: NSColor
	let barTextColor: NSColor
	let dividerLineColor: NSColor
	let appearance: NSAppearance?
	let textColor: NSColor
	let textHighlightColor: NSColor?
	let commentColor: NSColor
	let overflowColor: NSColor
	let fallbackBackgroundColor: NSColor
	let scrollerKnobStyle: NSScroller.KnobStyle
	
	static func withTheme(_ theme: ZGWindowStyleTheme) -> WindowStyle {
		switch theme {
		case .plain:
			return
				WindowStyle(
					barColor: NSColor(deviceWhite: 0.9, alpha: 1.0),
					barTextColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
					dividerLineColor: NSColor(deviceRed: 205.0 / 255.0, green: 205.0 / 255.0, blue: 205.0 / 255.0, alpha: 1.0),
					appearance: NSAppearance(named: .aqua),
					textColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
					textHighlightColor: nil,
					commentColor: NSColor.darkGray,
					overflowColor: NSColor(deviceRed: 1.0, green: 1.0, blue: 0.0, alpha: 0.3),
					fallbackBackgroundColor: NSColor(deviceRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.95),
					scrollerKnobStyle: .dark)
		case .dark:
			return
				WindowStyle(
					barColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
					barTextColor: NSColor(deviceRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
					dividerLineColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
					appearance: NSAppearance(named: .darkAqua),
					textColor: NSColor(deviceRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
					textHighlightColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 1.0, alpha: 0.4),
					commentColor: NSColor(deviceWhite: 1.0, alpha: 0.7),
					overflowColor: NSColor(deviceRed: 1.0, green: 0.690, blue: 0.231, alpha: 0.3),
					fallbackBackgroundColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.9),
					scrollerKnobStyle: .light)
		case .papyrus:
			return
				WindowStyle(
					barColor: NSColor(deviceRed: 1.0, green: 0.941, blue: 0.647, alpha: 0.95),
					barTextColor: NSColor(deviceRed: 0.714, green: 0.286, blue: 0.149, alpha: 1.0),
					dividerLineColor: NSColor(deviceRed: 188.0 / 255.0, green: 169.0 / 255.0, blue: 57.0 / 255.0, alpha: 0.55),
					appearance: NSAppearance(named: .aqua),
					textColor: NSColor(deviceRed: 0.557, green: 0.157, blue: 0.0, alpha: 1.0),
					textHighlightColor: nil,
					commentColor: NSColor(deviceRed: 0.714, green: 0.286, blue: 0.149, alpha: 1.0),
					overflowColor: NSColor(deviceRed: 1.0, green: 0.690, blue: 0.231, alpha: 0.5),
					fallbackBackgroundColor: NSColor(deviceRed: 1.0, green: 0.941, blue: 0.647, alpha: 0.9),
					scrollerKnobStyle: .dark)
		case .blue:
			let barAndTextHighlightColor = NSColor(deviceRed: 0.204, green: 0.596, blue: 0.859, alpha: 1.0)
			return
				WindowStyle(
					barColor: barAndTextHighlightColor,
					barTextColor: NSColor(deviceRed: 0.925, green: 0.941, blue: 0.945, alpha: 1.0),
					dividerLineColor: barAndTextHighlightColor,
					appearance: NSAppearance(named: .aqua),
					textColor: NSColor(deviceRed: 0.173, green: 0.243, blue: 0.314, alpha: 1.0),
					textHighlightColor: barAndTextHighlightColor,
					commentColor: NSColor(deviceRed: 0.161, green: 0.502, blue: 0.725, alpha: 1.0),
					overflowColor: NSColor(deviceRed: 0.831, green: 0.753, blue: 0.169, alpha: 0.3),
					fallbackBackgroundColor: NSColor(deviceRed: 0.925, green: 0.941, blue: 0.945, alpha: 0.9),
					scrollerKnobStyle: .dark)
		case .green:
			let barAndTextHighlightColor = NSColor(deviceRed: 0.361, green: 0.514, blue: 0.184, alpha: 1.0)
			return
				WindowStyle(
					barColor: barAndTextHighlightColor,
					barTextColor: NSColor(deviceRed: 0.847, green: 0.792, blue: 0.659, alpha: 1.0),
					dividerLineColor: barAndTextHighlightColor,
					appearance: NSAppearance(named: .aqua),
					textColor: NSColor(deviceRed: 0.157, green: 0.286, blue: 0.027, alpha: 1.0),
					textHighlightColor: barAndTextHighlightColor,
					commentColor: NSColor(deviceRed: 0.361, green: 0.514, blue: 0.184, alpha: 1.0),
					overflowColor: NSColor(deviceRed: 0.831, green: 0.753, blue: 0.169, alpha: 0.5),
					fallbackBackgroundColor: NSColor(deviceRed: 0.847, green: 0.792, blue: 0.659, alpha: 0.9),
					scrollerKnobStyle: .dark)
		case .red:
			let barAndTextHighlightColor = NSColor(deviceRed: 0.863, green: 0.208, blue: 0.133, alpha: 1.0)
			return
				WindowStyle(
					barColor: barAndTextHighlightColor,
					barTextColor: NSColor(deviceRed: 0.118, green: 0.118, blue: 0.125, alpha: 1.0),
					dividerLineColor: barAndTextHighlightColor,
					appearance: NSAppearance(named: .darkAqua),
					textColor: NSColor(deviceRed: 0.963, green: 0.308, blue: 0.233, alpha: 1.0),
					textHighlightColor: barAndTextHighlightColor,
					commentColor: NSColor(deviceRed: 0.863, green: 0.208, blue: 0.133, alpha: 1.0),
					overflowColor: NSColor(deviceRed: 1.0, green: 0.690, blue: 0.231, alpha: 0.3),
					fallbackBackgroundColor: NSColor(deviceRed: 0.165, green: 0.173, blue: 0.169, alpha: 0.95),
					scrollerKnobStyle: .light)
		}
	}
}
