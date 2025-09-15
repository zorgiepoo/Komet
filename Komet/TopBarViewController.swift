//
//  TopBarViewController.swift
//  Komet
//
//  Created by Mayur Pawashe on 6/19/25.
//  Copyright © 2025 zgcoder. All rights reserved.
//

import Cocoa

class TopBarViewController: NSViewController {
	@IBOutlet private var commitLabelTextField: NSTextField!
	@IBOutlet private var cancelButton: NSButton!
	@IBOutlet private var commitButton: NSButton!
	@IBOutlet var checkForUpdatesProgressIndicator: NSProgressIndicator!
	
	var commitHandler: (() -> ())? = nil
	var cancelHandler: (() -> ())? = nil
	
	init() {
		super.init(nibName: "Top Bar", bundle: Bundle.main)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		cancelButton.title = NSLocalizedString("topBarCancel", tableName: nil, comment: "")
		commitButton.title = NSLocalizedString("topBarCommit", tableName: nil, comment: "")
	}
	
	var style: WindowStyle? {
		didSet {
			guard let style else {
				return
			}
			
			// Style top bar
			do {
				view.wantsLayer = true
				view.layer?.backgroundColor = style.barColor.cgColor
				
				// Setting the top bar appearance will provide us a proper border for the commit button in dark and light themes
				view.appearance = style.appearance
			}
			
			// Style top bar buttons
			do {
				commitLabelTextField.textColor = style.barTextColor
				
				if #available(macOS 26.0, *) {
#if canImport(AppKit, _version: "2665.8")
					commitButton.borderShape = .capsule
					commitButton.tintProminence = .primary
#endif
					commitButton.bezelColor = style.primaryBarButtonColor
				} else {
					let commitTitle = NSMutableAttributedString(attributedString: commitButton.attributedTitle)
					commitTitle.addAttribute(.foregroundColor, value: style.barTextColor, range: NSMakeRange(0, commitTitle.length))
					commitButton.attributedTitle = commitTitle
				}
				
				if #available(macOS 26.0, *) {
#if canImport(AppKit, _version: "2665.8")
					cancelButton.borderShape = .capsule
					cancelButton.tintProminence = .primary
#endif
					cancelButton.isBordered = true
					cancelButton.bezelColor = style.secondaryBarButtonColor
				} else {
					let cancelTitle = NSMutableAttributedString(attributedString: cancelButton.attributedTitle)
					cancelTitle.addAttribute(.foregroundColor, value: style.barTextColor, range: NSMakeRange(0, cancelTitle.length))
					cancelButton.attributedTitle = cancelTitle
				}
			}
		}
	}
	
	func updateProjectName(_ projectName: String) {
		commitLabelTextField.stringValue = projectName
	}
    
	@IBAction @objc func cancelCommit(_ sender: Any?) {
		cancelHandler?()
	}
	
	@IBAction @objc func commit(_ sender: Any?) {
		commitHandler?()
	}
}
