//
//  UserDefaults.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/31/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Cocoa

func ZGReadDefaultFont(_ userDefaults: UserDefaults, _ fontNameDefaultsKey: String, _ fontSizeDefaultsKey: String) -> NSFont {
	let fontSize = userDefaults.double(forKey: fontSizeDefaultsKey)
	
	let font: NSFont?
	if let fontName = userDefaults.string(forKey: fontNameDefaultsKey), !fontName.isEmpty {
		if let userFont = NSFont(name: fontName, size: CGFloat(fontSize)) {
			font = userFont
		} else {
			font = NSFont.userFixedPitchFont(ofSize: CGFloat(fontSize))
		}
	} else {
		font = NSFont.userFixedPitchFont(ofSize: CGFloat(fontSize))
	}
	
	// Hopefully we will never hit the case of needing to use a system font
	return font ?? NSFont.systemFont(ofSize: CGFloat(fontSize))
}

func ZGWriteDefaultFont(_ userDefaults: UserDefaults, _ font: NSFont, _ fontNameKey: String, _ fontPointSizeKey: String) {
	userDefaults.set(font.fontName, forKey: fontNameKey)
	userDefaults.set(Double(font.pointSize), forKey: fontPointSizeKey)
}

func ZGRegisterDefaultFont(_ userDefaults: UserDefaults, _ fontNameKey: String, _ pointSizeKey: String) {
	userDefaults.register(defaults: [fontNameKey: "", pointSizeKey: 0.0])
}

func ZGReadDefaultLineLimit(_ userDefaults: UserDefaults, _ defaultsKey: String) -> Int {
	return min(1000, max(userDefaults.integer(forKey: defaultsKey), 0))
}

func ZGReadDefaultWindowStyleTheme(_ userDefaults: UserDefaults, _ defaultsKey: String) -> WindowStyleDefaultTheme {
	// The theme can be stored as either an integer or string (convertible to integer)
	// or be nil for automatic
	let readTheme: WindowStyleTheme? = userDefaults.object(forKey: defaultsKey).flatMap { themeDefault -> Int? in
		let integerValue = themeDefault as? Int
		return integerValue ?? (themeDefault as? String).flatMap({ Int($0) })
	}.flatMap({ WindowStyleTheme(rawValue: $0) })
	
	let defaultTheme: WindowStyleDefaultTheme = readTheme.flatMap({ .theme($0) }) ?? .automatic
	return defaultTheme
}

func ZGWriteDefaultStyleTheme(_ userDefaults: UserDefaults, _ defaultsKey: String, _ defaultTheme: WindowStyleDefaultTheme) {
	switch defaultTheme {
	case .automatic:
		userDefaults.removeObject(forKey: defaultsKey)
	case .theme(let theme):
		userDefaults.set(theme.rawValue, forKey: defaultsKey)
	}
}

func ZGReadDefaultTimeoutInterval(_ userDefaults: UserDefaults, _ defaultsKey: String, _ maxTimeout: TimeInterval) -> TimeInterval {
	let timeoutRead = userDefaults.double(forKey: defaultsKey)
	return min(max(0.0, timeoutRead), maxTimeout)
}

func ZGReadDefaultURL(_ userDefaults: UserDefaults, _ defaultsKey: String) -> URL? {
	if let urlString = userDefaults.string(forKey: defaultsKey), !urlString.isEmpty {
		return URL(fileURLWithPath: urlString)
	} else {
		return nil
	}
}
