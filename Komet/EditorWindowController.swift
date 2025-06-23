//
//  EditorWindowController.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/17/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Foundation
import AppKit

private let ZGEditorWindowFrameNameKey = "ZGEditorWindowFrame"
private let APP_SUPPORT_DIRECTORY_NAME = "Komet"

@objc class ZGEditorWindowController: NSWindowController, UserDefaultsEditorListener {
	
	private let fileURL: URL
	private let temporaryDirectoryURL: URL?
	private let tutorialMode: Bool
	
	private let initiallyContainedEmptyContent: Bool
	private let versionControlType: VersionControlType
	private let commentVersionControlType: VersionControlType
	private let projectNameDisplay: String
	
	private let breadcrumbsPath: String?
	
	private var style: WindowStyle
	private var effectiveAppearanceObserver: NSKeyValueObservation? = nil
	
	let topBarViewController: TopBarViewController
	private let commitContentViewController: ContentViewController
	private let horizontalLineDivider: ColoredDivider!
	
	// MARK: Static functions
	
	private static func styleTheme(defaultTheme: WindowStyleDefaultTheme, effectiveAppearance: NSAppearance) -> WindowStyleTheme {
		switch defaultTheme {
		case .automatic:
			let appearanceName = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
			let darkMode = (appearanceName == .darkAqua)
			
			return darkMode ? .dark : .plain
		case .theme(let theme):
			return theme
		}
	}
	
	// MARK: Initialization
	
	static func registerDefaults() {
		let userDefaults = UserDefaults.standard
		
		ZGRegisterDefaultFont(userDefaults, ZGMessageFontNameKey, ZGMessageFontPointSizeKey)
		ZGRegisterDefaultFont(userDefaults, ZGCommentsFontNameKey, ZGCommentsFontPointSizeKey)
		
		userDefaults.register(defaults: [
			ZGEditorRecommendedSubjectLengthLimitEnabledKey: true,
			// Not using 50 because I think it may be too irritating of a default for Mac users
			// GitHub's max limit is technically 72 so we are slightly shy under it
			ZGEditorRecommendedSubjectLengthLimitKey: 69,
			// Having a recommendation limit for body lines could be irritating as a default, so we disable it by default
			ZGEditorRecommendedBodyLineLengthLimitEnabledKey: false,
			ZGEditorRecommendedBodyLineLengthLimitKey: 72,
			ZGEditorAutomaticNewlineInsertionAfterSubjectKey: true,
			ZGResumeIncompleteSessionKey: true,
			ZGResumeIncompleteSessionTimeoutIntervalKey: 60.0 * 60, // around 1 hour
			ZGWindowVibrancyKey: false,
			ZGDisableSpellCheckingAndCorrectionForSquashesKey: true,
			ZGDisableAutomaticNewlineInsertionAfterSubjectLineForSquashesKey: true,
			ZGDetectHGCommentStyleForSquashesKey: true,
			ZGAssumeVersionControlledFileKey: true
		])
		
		ZGCommitTextView.registerDefaults()
	}
	
	required init(fileURL: URL, temporaryDirectoryURL: URL?, tutorialMode: Bool) {
		self.fileURL = fileURL
		self.temporaryDirectoryURL = temporaryDirectoryURL
		self.tutorialMode = tutorialMode
		
		let userDefaults = UserDefaults.standard
		
		let processInfo = ProcessInfo.processInfo
		breadcrumbsPath = processInfo.environment[ZGBreadcrumbsURLKey]
		
		let breadcrumbs: Breadcrumbs?
		if breadcrumbsPath != nil {
			breadcrumbs = Breadcrumbs()
		} else {
			breadcrumbs = nil
		}
		
		style = WindowStyle.withTheme(Self.styleTheme(defaultTheme: ZGReadDefaultWindowStyleTheme(userDefaults, ZGWindowStyleThemeKey), effectiveAppearance: NSApp.effectiveAppearance))
		
		// Detect squash message
		let isSquashMessage: Bool
		let loadedPlainString: String
		do {
			let plainStringCandidate = try String(contentsOf: self.fileURL, encoding: .utf8)
			
			// It's unlikely we'll get content that has no line break, but if we do,
			// just insert a newline character because Komet won't be able to deal with the content otherwise
			let lineCount = plainStringCandidate.components(separatedBy: .newlines).count
			loadedPlainString = (lineCount <= 1) ? "\n" : plainStringCandidate
			
			// Detect heuristically if this is a squash/rebase in git or hg
			// Scan the entire string contents for simplicity and handle both git and hg (with histedit extension)
			// Also test if the filename contains "rebase"
			isSquashMessage = fileURL.lastPathComponent.contains("rebase") || loadedPlainString.contains("= use commit")
		} catch {
			fatalError("Failed to parse commit data: \(error)")
		}
		
		// Detect version control type
		let fileManager = FileManager()
		let parentURL = self.fileURL.deletingLastPathComponent()
		let versionControlledFile = userDefaults.bool(forKey: ZGAssumeVersionControlledFileKey)
		
		let versionControlType: VersionControlType
		if tutorialMode || !versionControlledFile {
			versionControlType = .git
			self.projectNameDisplay = self.fileURL.lastPathComponent
		} else if parentURL.lastPathComponent == ".git" {
			// We don't *have* to detect this for git because we could look at the current working directory first,
			// but I want to rely on the current working directory as a last resort.
			
			versionControlType = .git
			self.projectNameDisplay = parentURL.deletingLastPathComponent().lastPathComponent
		} else {
			let lastPathComponent = self.fileURL.lastPathComponent
			if lastPathComponent.hasPrefix("hg-") {
				versionControlType = .hg
			} else if lastPathComponent.hasPrefix("svn-") {
				versionControlType = .svn
			} else {
				versionControlType = .git
			}
			
			if let projectNameFromEnvironment = processInfo.environment[ZGProjectNameKey] {
				self.projectNameDisplay = projectNameFromEnvironment
			} else {
				self.projectNameDisplay = URL(fileURLWithPath: fileManager.currentDirectoryPath).lastPathComponent
			}
		}
		
		self.versionControlType = versionControlType
		
		commentVersionControlType =
			(isSquashMessage && versionControlType == .hg && userDefaults.bool(forKey: ZGDetectHGCommentStyleForSquashesKey)) ?
			.git : versionControlType
		
		// Detect if there's empty content
		let loadedCommentSectionLength = !versionControlledFile ? 0 : TextProcessor.commentSectionLength(plainText: loadedPlainString, versionControlType: commentVersionControlType)
		let loadedCommitRange = TextProcessor.commitTextRange(plainText: loadedPlainString, commentLength: loadedCommentSectionLength)
		
		let loadedContent = loadedPlainString[loadedCommitRange.lowerBound ..< loadedCommitRange.upperBound]
		
		initiallyContainedEmptyContent = (loadedContent.trimmingCharacters(in: .newlines).count == 0)
		
		// Check if we have any incomplete commit message available
		// Load the incomplete commit message contents if our content is initially empty
		let lastSavedCommitMessage: String?
		if !self.tutorialMode && userDefaults.bool(forKey: ZGAssumeVersionControlledFileKey) && userDefaults.bool(forKey: ZGResumeIncompleteSessionKey) {
			if let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
				let supportDirectory = applicationSupportURL.appendingPathComponent(APP_SUPPORT_DIRECTORY_NAME)
				
				let lastCommitURL = supportDirectory.appendingPathComponent(projectNameDisplay)
				
				do {
					let reachable = try lastCommitURL.checkResourceIsReachable()
					if reachable {
						defer {
							// Always remove the last commit file on every launch
							let _ = try? fileManager.removeItem(at: lastCommitURL)
						}
						
						let resource = try lastCommitURL.resourceValues(forKeys: [.attributeModificationDateKey])
						let lastModifiedDate = resource.attributeModificationDate
						
						// Use a timeout interval for using the last incomplete commit message
						// If too much time passes by, chances are the user may want to start anew
						let maxTimeout = 60.0 * 60.0 * 24 * 7 * 5 // around a month
						let timeoutInterval = ZGReadDefaultTimeoutInterval(userDefaults, ZGResumeIncompleteSessionTimeoutIntervalKey, maxTimeout)
						let intervalSinceLastSavedCommitMessage = lastModifiedDate.flatMap({ Date().timeIntervalSince($0) }) ?? 0.0
						
						if initiallyContainedEmptyContent && intervalSinceLastSavedCommitMessage >= 0.0 && intervalSinceLastSavedCommitMessage <= timeoutInterval {
							lastSavedCommitMessage = try String(contentsOf: lastCommitURL, encoding: .utf8)
						} else {
							lastSavedCommitMessage = nil
						}
					} else {
						lastSavedCommitMessage = nil
					}
				} catch {
					print("Failed to load last saved commit message: \(error)")
					lastSavedCommitMessage = nil
				}
			} else {
				print("Failed to find application support directory")
				lastSavedCommitMessage = nil
			}
		} else {
			lastSavedCommitMessage = nil
		}
		
		let initialPlainText: String
		let initialCommitTextRange: Range<String.UTF16View.Index>
		let resumedFromSavedCommit: Bool
		let commentSectionLength: Int
		
		if let savedCommitMessage = lastSavedCommitMessage {
			initialPlainText = savedCommitMessage.appending(loadedPlainString)
			commentSectionLength = !versionControlledFile ? 0 : TextProcessor.commentSectionLength(plainText: initialPlainText, versionControlType: commentVersionControlType)
			initialCommitTextRange = TextProcessor.commitTextRange(plainText: initialPlainText, commentLength: commentSectionLength)
			resumedFromSavedCommit = true
		} else {
			initialPlainText = loadedPlainString
			commentSectionLength = loadedCommentSectionLength
			initialCommitTextRange = loadedCommitRange
			resumedFromSavedCommit = false
		}
		
		topBarViewController = TopBarViewController()
		commitContentViewController = ContentViewController(initialPlainText: initialPlainText, commentSectionLength: commentSectionLength, commentVersionControlType: commentVersionControlType, resumedFromSavedCommit: resumedFromSavedCommit, initialCommitTextRange: initialCommitTextRange, isSquashMessage: isSquashMessage, breadcrumbs: breadcrumbs)
		horizontalLineDivider = ColoredDivider()
		
		super.init(window: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		effectiveAppearanceObserver?.invalidate()
	}
	
	override var windowNibName: String {
		return "Commit Editor"
	}
	
	private func updateCurrentStyle() {
		topBarViewController.style = style
		commitContentViewController.style = style
		horizontalLineDivider.fillColor = style.dividerLineColor
	}
	
	private func updateStyle(_ newStyle: WindowStyle) {
		style = newStyle
		updateCurrentStyle()
	}
	
	private func updateEditorStyle(_ style: WindowStyle) {
		updateStyle(style)
		commitContentViewController.reloadTextAttributes()
		
		topBarViewController.view.needsDisplay = true
		commitContentViewController.view.needsDisplay = true
	}
	
	@objc override func windowDidLoad() {
		let commitHandler: () -> () = { [weak self] in
			self?.commit(nil)
		}
		
		let cancelHandler: () -> () = { [weak self] in
			self?.cancelCommit(nil)
		}
		
		topBarViewController.commitHandler = commitHandler
		topBarViewController.cancelHandler = cancelHandler
		
		commitContentViewController.commitHandler = commitHandler
		commitContentViewController.cancelHandler = cancelHandler
		
		// Set up views
		if let contentView = self.window?.contentView {
			do {
				contentView.addSubview(topBarViewController.view)
				
				topBarViewController.view.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					topBarViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
					topBarViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
					topBarViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
				])
			}
			
			do {
				contentView.addSubview(horizontalLineDivider)
				
				horizontalLineDivider.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					horizontalLineDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
					horizontalLineDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
					horizontalLineDivider.topAnchor.constraint(equalTo: topBarViewController.view.bottomAnchor),
				])
			}
			
			do {
				contentView.addSubview(commitContentViewController.view)
				
				commitContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					commitContentViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
					commitContentViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
					commitContentViewController.view.topAnchor.constraint(equalTo: horizontalLineDivider.bottomAnchor),
					commitContentViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
				])
			}
		}
		
		self.updateCurrentStyle()
		
		let userDefaults = UserDefaults.standard
		
		self.window?.setFrameUsingName(ZGEditorWindowFrameNameKey)
		
		// Update style when user changes the system appearance
		self.effectiveAppearanceObserver = NSApp.observe(\.effectiveAppearance, options: [.old, .new]) { [weak self] (application, change) in
			guard let self = self else {
				return
			}
			
			if change.oldValue?.name != change.newValue?.name {
				let defaultTheme = ZGReadDefaultWindowStyleTheme(userDefaults, ZGWindowStyleThemeKey)
				let theme = Self.styleTheme(defaultTheme: defaultTheme, effectiveAppearance: application.effectiveAppearance)
				
				self.updateEditorStyle(WindowStyle.withTheme(theme))
			}
		}
		
		// Customize window
		if let window = window {
			window.titlebarAppearsTransparent = true
			
			// Hide the window titlebar buttons
			// We still want the resize functionality to work even though the button is hidden
			window.standardWindowButton(.closeButton)?.isHidden = true
			window.standardWindowButton(.miniaturizeButton)?.isHidden = true
			window.standardWindowButton(.zoomButton)?.isHidden = true
			
			if #available(macOS 13, *) {
				// Make window join stage manager spaces
				window.collectionBehavior = .canJoinAllApplications;
			}
		}
		
		// Show project name
		topBarViewController.updateProjectName(projectNameDisplay)
		
		func showBranchName() {
			let toolName: String
			let toolArguments: [String]
			
			switch versionControlType {
			case .git:
				toolName = "git"
				toolArguments = ["rev-parse", "--symbolic-full-name", "--abbrev-ref", "HEAD"]
			case .hg:
				toolName = "hg"
				toolArguments = ["branch"]
			case .svn:
				return
			}
			
			if let toolURL = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":").map({ parentDirectoryPath -> URL in
				return URL(fileURLWithPath: parentDirectoryPath).appendingPathComponent(toolName)
			}).first(where: { toolURL -> Bool in
				let reachable = try? toolURL.checkResourceIsReachable()
				return reachable ?? false
			}) {
				DispatchQueue.global(qos: .userInteractive).async {
					let process = Process()
					process.executableURL = toolURL
					process.arguments = toolArguments
					
					let pipe = Pipe()
					process.standardOutput = pipe
					
					do {
						try process.run()
						process.waitUntilExit()
						
						if process.terminationStatus == EXIT_SUCCESS {
							let data = pipe.fileHandleForReading.readDataToEndOfFile()
							if let branchName = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), branchName.count > 0 {
								DispatchQueue.main.async {
									let projectNameWithBranch = "\(self.projectNameDisplay) (\(branchName))"
									self.topBarViewController.updateProjectName(projectNameWithBranch)
								}
							}
						}
					} catch {
						print("Failed to retrieve branch name: \(error)")
					}
				}
			}
		}
		
		// Show branch name if available
		let versionControlledFile = userDefaults.bool(forKey: ZGAssumeVersionControlledFileKey)
		if !tutorialMode && versionControlledFile {
			showBranchName()
		}
	}
	
	// MARK: Actions
	
	private func exit(status: Int32) -> Never {
		if let breadcrumbsPath = breadcrumbsPath {
			if let enableContentsBreadcrumbs = ProcessInfo.processInfo.environment[ZGBreadcrumbsEnableContentKey], enableContentsBreadcrumbs == "true" || enableContentsBreadcrumbs == "1" {
				commitContentViewController.updateBreadcrumbsIfNeeded()
			}
			
			if var breadcrumbs = commitContentViewController.breadcrumbs {
				let breadcrumbsURL = URL(fileURLWithPath: breadcrumbsPath, isDirectory: false)
				breadcrumbs.exitStatus = status
				
				do {
					let jsonData = try JSONEncoder().encode(breadcrumbs)
					try jsonData.write(to: breadcrumbsURL, options: .atomic)
				} catch {
					print("Failed to save breadcrumbs: \(error)")
				}
			}
		}
		
		Darwin.exit(status)
	}
	
	func exit(success: Bool) -> Never {
		self.window?.saveFrame(usingName: ZGEditorWindowFrameNameKey)
		
		let fileManager = FileManager.default
		if let temporaryDirectoryURL = temporaryDirectoryURL {
			let _ = try? fileManager.removeItem(at: temporaryDirectoryURL)
		}
		
		if success {
			// We should have wrote to the commit file successfully
			exit(status: EXIT_SUCCESS)
		} else {
			let userDefaults = UserDefaults.standard
			let versionControlledFile = userDefaults.bool(forKey: ZGAssumeVersionControlledFileKey)
			if !versionControlledFile || !initiallyContainedEmptyContent {
				// If we aren't dealing with a version controlled file or are amending an existing commit for example, we should fail and not create another change
				exit(status: EXIT_FAILURE)
			} else {
				// If we initially had no content and wrote an incomplete commit message,
				// then save the commit message in case we may want to resume from it later
				if userDefaults.bool(forKey: ZGResumeIncompleteSessionKey) {
					let commitMessageContent = commitContentViewController.commitMessageContent()
					if commitMessageContent.count > 0 {
						do {
							let applicationSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
							
							let supportDirectory = applicationSupportURL.appendingPathComponent(APP_SUPPORT_DIRECTORY_NAME)
							
							try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true, attributes: nil)
							
							let lastCommitURL = supportDirectory.appendingPathComponent(projectNameDisplay)
							
							try commitMessageContent.write(to: lastCommitURL, atomically: true, encoding: .utf8)
						} catch {
							print("Failed to save incomplete commit: \(error)")
						}
					}
				}
				
				// Empty commits should be treated as a success
				// Version control software will be able to handle it as an abort
				exit(status: EXIT_SUCCESS)
			}
		}
	}
	
	@IBAction @objc func commit(_ sender: Any?) {
		let plainText = commitContentViewController.currentPlainText()
		
		do {
			try plainText.write(to: fileURL, atomically: true, encoding: .utf8)
			exit(success: true)
		} catch {
			print("Failed to write file for commit: \(error)")
			
			if let window = self.window {
				let alert = NSAlert(error: error)
				alert.alertStyle = .critical
				alert.beginSheetModal(for: window) { response in
				}
			}
		}
	}
	
	@IBAction @objc func cancelCommit(_ sender: Any?) {
		exit(success: false)
	}
	
	@IBAction @objc func changeEditorTheme(_ sender: Any) {
		guard let menuItem = sender as? NSMenuItem else {
			return
		}
		
		guard let newDefaultTheme = WindowStyleDefaultTheme(tag: menuItem.tag) else {
			print("Unsupported theme with tag: \(menuItem.tag)")
			return
		}
		
		let userDefaults = UserDefaults.standard
		let currentDefaultTheme = ZGReadDefaultWindowStyleTheme(userDefaults, ZGWindowStyleThemeKey)
		if newDefaultTheme != currentDefaultTheme {
			ZGWriteDefaultStyleTheme(userDefaults, ZGWindowStyleThemeKey, newDefaultTheme)
			let newTheme = Self.styleTheme(defaultTheme: newDefaultTheme, effectiveAppearance: NSApp.effectiveAppearance)
			
			updateEditorStyle(WindowStyle.withTheme(newTheme))
		}
	}
	
	@IBAction @objc func changeVibrancy(_ sender: Any) {
		let userDefaults = UserDefaults.standard
		let vibrancy = userDefaults.bool(forKey: ZGWindowVibrancyKey)
		userDefaults.set(!vibrancy, forKey: ZGWindowVibrancyKey)
		
		updateCurrentStyle()
	}
	
	@objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
		case #selector(changeEditorTheme(_:)):
			let currentDefaultTheme = ZGReadDefaultWindowStyleTheme(UserDefaults.standard, ZGWindowStyleThemeKey)
			menuItem.state = (menuItem.tag == currentDefaultTheme.tag) ? .on : .off
			break
		case #selector(changeVibrancy(_:)):
			menuItem.state = UserDefaults.standard.bool(forKey: ZGWindowVibrancyKey) ? .on : .off
			break
		default:
			break
		}
		return true
	}
	
	// MARK: UserDefaultsEditorListener
	
	@objc func userDefaultsChangedMessageFont() {
		commitContentViewController.reloadTextAttributes()
	}
	
	@objc func userDefaultsChangedCommentsFont() {
		commitContentViewController.reloadTextAttributes()
	}
	
	@objc func userDefaultsChangedRecommendedLineLengthLimits() {
		commitContentViewController.reloadTextAttributes()
	}
	
	@objc func userDefaultsChangedVibrancy() {
		updateCurrentStyle()
	}
}
