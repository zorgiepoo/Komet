//
//  UserDefaultsEditorListener.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/1/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

protocol UserDefaultsEditorListener: AnyObject {
	func userDefaultsChangedMessageFont()
	func userDefaultsChangedCommentsFont()
	func userDefaultsChangedRecommendedLineLengthLimits()
}
