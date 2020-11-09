//
//  CommitTextView.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/17/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import AppKit

@objc protocol ZGCommitViewDelegate {
	func zgCommitViewSelectAll()
	@objc func zgCommitViewTouchCommit(_ sender: Any)
	@objc func zgCommitViewTouchCancel(_ sender: Any)
}

private let ZGTouchBarIdentifier = "org.zgcoder.Komet.67e9f8738561"
private let ZGTouchBarIdentifierCancel = "zgCancelIdentifier"
private let ZGTouchBarIdentifierCommit = "zgCommitIdentifier"

@objc class ZGCommitTextView: NSTextView {
	@objc weak var zgCommitViewDelegate: ZGCommitViewDelegate?
	
	private var disabledContinuousSpellingAndAutomaticSpellingCorrection = false
	
	static func registerDefaults() {
		let userDefaults = UserDefaults.standard
		userDefaults.register(defaults: [
			ZGCommitTextViewContinuousSpellCheckingKey: true,
			ZGCommitTextViewAutomaticSpellingCorrectionKey: NSSpellChecker.isAutomaticSpellingCorrectionEnabled,
			ZGCommitTextViewAutomaticTextReplacementKey: NSSpellChecker.isAutomaticTextReplacementEnabled
		])
	}
	
	@objc func zgLoadDefaults() {
		let defaults = UserDefaults.standard
		
		super.isContinuousSpellCheckingEnabled = defaults.bool(forKey: ZGCommitTextViewContinuousSpellCheckingKey)
		super.isAutomaticSpellingCorrectionEnabled = defaults.bool(forKey: ZGCommitTextViewAutomaticSpellingCorrectionKey)
		super.isAutomaticTextReplacementEnabled = defaults.bool(forKey: ZGCommitTextViewAutomaticTextReplacementKey)
	}
	
	@objc func zgDisableContinuousSpellingAndAutomaticSpellingCorrection() {
		super.isContinuousSpellCheckingEnabled = false
		super.isAutomaticSpellingCorrectionEnabled = false
		super.isAutomaticTextReplacementEnabled = false
		
		disabledContinuousSpellingAndAutomaticSpellingCorrection = true
	}
	
	override var isContinuousSpellCheckingEnabled: Bool {
		set {
			if !disabledContinuousSpellingAndAutomaticSpellingCorrection {
				UserDefaults.standard.set(newValue, forKey: ZGCommitTextViewContinuousSpellCheckingKey)
			}
			super.isContinuousSpellCheckingEnabled = newValue
		}
		get {
			return super.isContinuousSpellCheckingEnabled
		}
	}
	
	override var isAutomaticSpellingCorrectionEnabled: Bool {
		set {
			if !disabledContinuousSpellingAndAutomaticSpellingCorrection {
				UserDefaults.standard.set(newValue, forKey: ZGCommitTextViewAutomaticSpellingCorrectionKey)
			}
			super.isAutomaticSpellingCorrectionEnabled = newValue
		}
		get {
			return super.isAutomaticSpellingCorrectionEnabled
		}
	}
	
	override var isAutomaticTextReplacementEnabled: Bool {
		set {
			if !disabledContinuousSpellingAndAutomaticSpellingCorrection {
				UserDefaults.standard.set(newValue, forKey: ZGCommitTextViewAutomaticTextReplacementKey)
			}
			super.isAutomaticTextReplacementEnabled = newValue
		}
		get {
			return super.isAutomaticTextReplacementEnabled
		}
	}
	
	@objc override func selectAll(_ sender: Any?) {
		if let commitViewDelegate = zgCommitViewDelegate {
			commitViewDelegate.zgCommitViewSelectAll()
		} else {
			super.selectAll(sender)
		}
	}
	
	private static func makeCustomTouchBarButton(identifier: NSTouchBarItem.Identifier, title: String, target: Any?, action: Selector) -> NSCustomTouchBarItem {
		let touchBarItem = NSCustomTouchBarItem(identifier: identifier)
		touchBarItem.view = NSButton(title: title, target: target, action: action)
		touchBarItem.customizationLabel = title
		return touchBarItem
	}
	
	@objc override func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		switch identifier.rawValue {
		case ZGTouchBarIdentifierCancel:
			return Self.makeCustomTouchBarButton(identifier: identifier, title: NSLocalizedString("touchBarCancel", tableName: nil, comment: ""), target: zgCommitViewDelegate, action: #selector(ZGCommitViewDelegate.zgCommitViewTouchCancel(_:)))
		case ZGTouchBarIdentifierCommit:
			return Self.makeCustomTouchBarButton(identifier: identifier, title: NSLocalizedString("touchBarCommit", tableName: nil, comment: ""), target: zgCommitViewDelegate, action: #selector(ZGCommitViewDelegate.zgCommitViewTouchCommit(_:)))
		default:
			return super.touchBar(touchBar, makeItemForIdentifier: identifier)
		}
	}
	
	@objc override func makeTouchBar() -> NSTouchBar? {
		let touchBar = NSTouchBar()
		touchBar.customizationIdentifier = ZGTouchBarIdentifier
		touchBar.delegate = self
		touchBar.defaultItemIdentifiers = [.characterPicker, NSTouchBarItem.Identifier(ZGTouchBarIdentifierCommit), .candidateList]
		touchBar.customizationAllowedItemIdentifiers = [.characterPicker, NSTouchBarItem.Identifier(ZGTouchBarIdentifierCancel), NSTouchBarItem.Identifier(ZGTouchBarIdentifierCommit), .flexibleSpace, .candidateList]
		return touchBar
	}
}
