//
//  PreferencesWindowController.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/31/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Cocoa

enum FontType {
	case message
	case comments
}

@objc class ZGPreferencesWindowController: NSWindowController {
	private weak var editorListener: ZGUserDefaultsEditorListener?
	private weak var updaterListener: ZGUpdaterSettingsListener?
	
	private var selectedFontType: FontType? = nil
	
	@IBOutlet private var fontsView: NSView!
	@IBOutlet private var warningsView: NSView!
	@IBOutlet private var advancedView: NSView!
	
	@IBOutlet private var messageFontTextField: NSTextField!
	@IBOutlet private var commentsFontTextField: NSTextField!
	
	@IBOutlet private var recommendedSubjectLengthLimitTextField: NSTextField!
	@IBOutlet private var recommendedSubjectLengthLimitEnabledCheckbox: NSButton!
	@IBOutlet private var recommendedSubjectLengthLimitDescriptionTextField: NSTextField!
	
	@IBOutlet private var recommendedBodyLineLengthLimitTextField: NSTextField!
	@IBOutlet private var recommendedBodyLineLengthLimitEnabledCheckbox: NSButton!
	@IBOutlet private var recommendedBodyLineLengthLimitDescriptionTextField: NSTextField!
	
	@IBOutlet private var automaticNewlineInsertionAfterSubjectLineCheckbox: NSButton!
	@IBOutlet private var resumeLastIncompleteSessionCheckbox: NSButton!
	@IBOutlet private var automaticallyInstallUpdatesCheckbox: NSButton!
	
	private let ZGToolbarFontsIdentifier = "fonts"
	private let ZGToolbarWarningsIdentifier = "warnings"
	private let ZGToolbarAdvancedIdentifier = "advanced"
	
	required init(editorListener: ZGUserDefaultsEditorListener, updaterListener: ZGUpdaterSettingsListener) {
		self.editorListener = editorListener
		self.updaterListener = updaterListener
		
		super.init(window: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var windowNibName: String {
		return "Preferences"
	}
	
	@objc override func windowDidLoad() {
		showFonts(nil)
	}
	
	private func updateFont(_ font: NSFont, textField: NSTextField) {
		textField.font = font
		textField.stringValue = String(format: "%@ - %0.1f", font.fontName, font.pointSize)
	}
	
	private func changeToolbarItem(contentView: NSView, toolbarIdentifier: String) {
		if let window = self.window {
			window.contentView = contentView
			window.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: toolbarIdentifier)
		}
	}
	
	@IBAction func showFonts(_ sender: Any?) {
		changeToolbarItem(contentView: fontsView, toolbarIdentifier: ZGToolbarFontsIdentifier)
		
		let userDefaults = UserDefaults.standard
		
		let messageFont = ZGReadDefaultFont(userDefaults, ZGMessageFontNameKey, ZGMessageFontPointSizeKey)
		let commentsFont = ZGReadDefaultFont(userDefaults, ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey)
		
		updateFont(messageFont, textField: messageFontTextField)
		updateFont(commentsFont, textField: commentsFontTextField)
	}
	
	private func showFontPrompt(selectedFont: NSFont, fontType: FontType) {
		selectedFontType = fontType
		
		let fontManager = NSFontManager.shared
		fontManager.setSelectedFont(selectedFont, isMultiple: false)
		fontManager.orderFrontFontPanel(nil)
	}
	
	@IBAction func changeMessageFont(_ sender: Any) {
		let messageFont = ZGReadDefaultFont(UserDefaults.standard, ZGMessageFontNameKey, ZGMessageFontPointSizeKey)
		showFontPrompt(selectedFont: messageFont, fontType: .message)
	}
	
	@IBAction func changeCommentsFont(_ sender: Any) {
		let commentsFont = ZGReadDefaultFont(UserDefaults.standard, ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey)
		showFontPrompt(selectedFont: commentsFont, fontType: .comments)
	}
	
	@objc func changeFont(_ sender: Any?) {
		let fontManager = NSFontManager.shared
		guard let selectedFont = fontManager.selectedFont, let selectedFontType = selectedFontType else {
			return
		}
		
		let convertedFont = fontManager.convert(selectedFont)
		switch selectedFontType {
		case .message:
			ZGWriteDefaultFont(UserDefaults.standard, convertedFont, ZGMessageFontNameKey, ZGMessageFontPointSizeKey)
			editorListener?.userDefaultsChangedMessageFont()
			updateFont(convertedFont, textField: messageFontTextField)
			break
		case .comments:
			ZGWriteDefaultFont(UserDefaults.standard, convertedFont, ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey)
			editorListener?.userDefaultsChangedCommentsFont()
			updateFont(convertedFont, textField: commentsFontTextField)
			break
		}
	}
	
	private func setDescriptionTextField(_ textField: NSTextField, enabled: Bool) {
		textField.textColor = enabled ? NSColor.controlTextColor : NSColor.disabledControlTextColor
	}
	
	@IBAction func showWarnings(_ sender: Any) {
		changeToolbarItem(contentView: warningsView, toolbarIdentifier: ZGToolbarWarningsIdentifier)
		
		let userDefaults = UserDefaults.standard
		
		func updateLengthLimit(defaultsEnabledKey: String, checkbox: NSButton, defaultsLimitKey: String, textField: NSTextField, descriptionTextField: NSTextField) {
			textField.integerValue = ZGReadDefaultLineLimit(userDefaults, defaultsLimitKey)
			
			let enabledLimit = userDefaults.bool(forKey: defaultsEnabledKey)
			checkbox.state = enabledLimit ? .on : .off
			textField.isEnabled = enabledLimit
			
			setDescriptionTextField(descriptionTextField, enabled: enabledLimit)
		}
		
		updateLengthLimit(defaultsEnabledKey: ZGEditorRecommendedSubjectLengthLimitEnabledKey, checkbox: recommendedSubjectLengthLimitEnabledCheckbox, defaultsLimitKey: ZGEditorRecommendedSubjectLengthLimitKey, textField: recommendedSubjectLengthLimitTextField, descriptionTextField: recommendedSubjectLengthLimitDescriptionTextField)
		
		updateLengthLimit(defaultsEnabledKey: ZGEditorRecommendedBodyLineLengthLimitEnabledKey, checkbox: recommendedBodyLineLengthLimitEnabledCheckbox, defaultsLimitKey: ZGEditorRecommendedBodyLineLengthLimitKey, textField: recommendedBodyLineLengthLimitTextField, descriptionTextField: recommendedBodyLineLengthLimitDescriptionTextField)
	}
	
	private func changeLengthLimitEnabled(defaultsEnabledKey: String, checkbox: NSButton, textField: NSTextField, descriptionTextField: NSTextField) {
		let enabled = checkbox.state == .on
		UserDefaults.standard.set(enabled, forKey: defaultsEnabledKey)
		
		textField.isEnabled = enabled
		setDescriptionTextField(descriptionTextField, enabled: enabled)
		editorListener?.userDefaultsChangedRecommendedLineLengthLimits()
	}
	
	private func changeLengthLimit(defaultsLimitKey: String, textField: NSTextField) {
		UserDefaults.standard.set(textField.integerValue, forKey: defaultsLimitKey)
		editorListener?.userDefaultsChangedRecommendedLineLengthLimits()
	}
	
	@IBAction func changeRecommendedSubjectLengthLimitEnabled(_ sender: Any) {
		changeLengthLimitEnabled(defaultsEnabledKey: ZGEditorRecommendedSubjectLengthLimitEnabledKey, checkbox: recommendedSubjectLengthLimitEnabledCheckbox, textField: recommendedSubjectLengthLimitTextField, descriptionTextField: recommendedSubjectLengthLimitDescriptionTextField)
	}
	
	@IBAction func changeRecommendedSubjectLengthLimit(_ sender: Any) {
		changeLengthLimit(defaultsLimitKey: ZGEditorRecommendedSubjectLengthLimitKey, textField: recommendedSubjectLengthLimitTextField)
	}
	
	@IBAction func changeRecommendedBodyLineLengthLimitEnabled(_ sender: Any) {
		changeLengthLimitEnabled(defaultsEnabledKey: ZGEditorRecommendedBodyLineLengthLimitEnabledKey, checkbox: recommendedBodyLineLengthLimitEnabledCheckbox, textField: recommendedBodyLineLengthLimitTextField, descriptionTextField: recommendedBodyLineLengthLimitDescriptionTextField)
	}
	
	@IBAction func changeRecommendedBodyLineLengthLimit(_ sender: Any) {
		changeLengthLimit(defaultsLimitKey: ZGEditorRecommendedBodyLineLengthLimitKey, textField: recommendedBodyLineLengthLimitTextField)
	}
	
	@IBAction func showAdvanced(_ sender: Any) {
		changeToolbarItem(contentView: advancedView, toolbarIdentifier: ZGToolbarAdvancedIdentifier)
		
		let userDefaults = UserDefaults.standard
		
		let automaticInsertion = userDefaults.bool(forKey: ZGEditorAutomaticNewlineInsertionAfterSubjectKey)
		automaticNewlineInsertionAfterSubjectLineCheckbox.state = automaticInsertion ? .on : .off
		
		let resumeIncompleteSession = userDefaults.bool(forKey: ZGResumeIncompleteSessionKey)
		resumeLastIncompleteSessionCheckbox.state = resumeIncompleteSession ? .on : .off
		
		let mainBundle = Bundle.main
		let updaterSettings = SPUUpdaterSettings(hostBundle: mainBundle)
		let fileManager = FileManager()
		
		let bundleURL = mainBundle.bundleURL
		
		// This isn't a perfect check to see if we can update our app without any user interaction, but it's good enough for our purposes
		// (Sparkle has a better check, but it's not as simple/efficient. Even if we are wrong here, Sparkle still won't be able to install updates automatically).
		let canWriteToApp = fileManager.isWritableFile(atPath: bundleURL.path) && fileManager.isWritableFile(atPath: bundleURL.deletingLastPathComponent().path)
		
		automaticallyInstallUpdatesCheckbox.state = (canWriteToApp && updaterSettings.automaticallyChecksForUpdates) ? .on : .off
		automaticallyInstallUpdatesCheckbox.isEnabled = canWriteToApp
	}
	
	@IBAction func changeAutomaticNewlineInsertionAfterSubjectLine(_ sender: Any) {
		UserDefaults.standard.set(automaticNewlineInsertionAfterSubjectLineCheckbox.state == .on, forKey: ZGEditorAutomaticNewlineInsertionAfterSubjectKey)
	}
	
	@IBAction func changeResumeLastIncompleteSession(_ sender: Any) {
		UserDefaults.standard.set(resumeLastIncompleteSessionCheckbox.state == .on, forKey: ZGResumeIncompleteSessionKey)
	}
	
	@IBAction func changeAutomaticallyInstallUpdates(_ sender: Any) {
		updaterListener?.updaterSettingsChangedAutomaticallyInstallingUpdates(automaticallyInstallUpdatesCheckbox.state == .on)
	}
}
