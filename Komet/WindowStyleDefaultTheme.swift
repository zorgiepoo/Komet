//
//  WindowStyleDefaultTheme.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/8/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

private let WindowStyleAutomaticTag = -1

enum WindowStyleDefaultTheme: Equatable {
	case theme(WindowStyleTheme)
	case automatic
	
	init?(tag: Int) {
		switch tag {
		case WindowStyleAutomaticTag:
			self = .automatic
		default:
			if let windowStyleTheme = WindowStyleTheme(rawValue: tag) {
				self = .theme(windowStyleTheme)
			} else {
				return nil
			}
		}
	}
	
	var tag: Int {
		get {
			switch self {
			case .automatic:
				return WindowStyleAutomaticTag
			case .theme(let windowStyleTheme):
				return windowStyleTheme.rawValue
			}
		}
	}
}
