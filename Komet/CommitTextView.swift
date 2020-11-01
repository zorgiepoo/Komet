//
//  CommitTextView.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/17/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import AppKit

@objc protocol ZGCommitViewDelegate: NSTextViewDelegate, NSTouchBarDelegate {
	@objc func zgCommitViewSelectAll()
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
	
	@objc override func setContinuousSpellCheckingEnabled(_ continuousSpellCheckingEnabled: Bool) {
		if !disabledContinuousSpellingAndAutomaticSpellingCorrection {
			UserDefaults.standard.set(continuousSpellCheckingEnabled, forKey: ZGCommitTextViewContinuousSpellCheckingKey)
		}
		
		super.setContinuousSpellCheckingEnabled(continuousSpellCheckingEnabled)
	}
	
	@objc override func setAutomaticSpellingCorrectionEnabled(_ automaticSpellingCorrectionEnabled: Bool) {
		if !disabledContinuousSpellingAndAutomaticSpellingCorrection {
			UserDefaults.standard.set(automaticSpellingCorrectionEnabled, forKey: ZGCommitTextViewAutomaticSpellingCorrectionKey)
		}
		
		super.setAutomaticSpellingCorrectionEnabled(automaticSpellingCorrectionEnabled)
	}
	
	@objc override func setAutomaticTextReplacementEnabled(_ automaticTextReplacementEnabled: Bool) {
		if !disabledContinuousSpellingAndAutomaticSpellingCorrection {
			UserDefaults.standard.set(automaticTextReplacementEnabled, forKey: ZGCommitTextViewAutomaticTextReplacementKey)
		}
		
		super.setAutomaticTextReplacementEnabled(automaticTextReplacementEnabled)
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
