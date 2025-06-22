//
//  AppDelegate.swift
//  Komet
//
//  Created by Mayur Pawashe on 10/17/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Foundation
import AppKit

// For better clarity to differentiate between the struct statfs vs function statfs
typealias StatFS = statfs

@objc class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
	private var editorWindowController: ZGEditorWindowController?
	private var preferencesWindowController: ZGPreferencesWindowController?
	private var updaterController: UpdaterController?
	
	@objc override init() {
		ZGEditorWindowController.registerDefaults()
		
		super.init()
	}
	
	@objc func applicationDidFinishLaunching(_ notification: Notification) {
		if #available(macOS 14.0, *) {
			if !UserDefaults.standard.bool(forKey: ZGUseLegacyAppActivationKey) {
				NSApp.activate()
			} else {
				NSApp.activate(ignoringOtherApps: true)
			}
		} else {
			NSApp.activate(ignoringOtherApps: true)
		}
		
		NSApp.isAutomaticCustomizeTouchBarMenuItemEnabled = true
		
		guard let executableURL = Bundle.main.executableURL else {
			fatalError("Failed to retrieve executable URL of main app bundle")
		}
		let executablePathComponents = executableURL.pathComponents
		
		let fileManager = FileManager()
		
		// The system can pass command line arguments unfortunately
		// So to distinguish between a user starting the app normally and a tool like git launching the app,
		// we should see detect if the file exists
		let arguments = ProcessInfo.processInfo.arguments
		let inputFileURL: URL? = (arguments.count >= 2) ? URL(fileURLWithPath: arguments[1]) : nil
		
		let tutorialMode: Bool
		let commitFileURL: URL
		let tempDirectoryURL: URL?
		
		if let fileURL = inputFileURL, let reachable = try? fileURL.checkResourceIsReachable(), reachable {
			tutorialMode = false
			commitFileURL = fileURL
			tempDirectoryURL = nil
		} else {
			tutorialMode = true
			
			let executableIsOnReadOnlyMount = executableURL.withUnsafeFileSystemRepresentation { fileSystemRepresentation -> Bool in
				var statInfo = StatFS()
				let result = statfs(fileSystemRepresentation, &statInfo)
				return (result == 0) && ((statInfo.f_flags & UInt32(MNT_RDONLY)) != 0)
			}
			
			let suggestMovingApp: Bool
			if executableIsOnReadOnlyMount {
				suggestMovingApp = true
			} else {
				let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
				let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
				let developerURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Developer")
				
				let isSubdirectory: ([String]?, [String]) -> Bool = { (parentDirectoryPathComponents, filePathComponents) in
					guard let parentDirectoryPathComponents = parentDirectoryPathComponents, parentDirectoryPathComponents.count <= filePathComponents.count else {
						return false
					}
					
					return (Array(filePathComponents[0 ..< parentDirectoryPathComponents.count]) == parentDirectoryPathComponents)
				}
				
				suggestMovingApp = [downloadsURL, desktopURL, developerURL].contains { parentDirectoryURL -> Bool in
					return isSubdirectory(parentDirectoryURL?.pathComponents, executablePathComponents)
				}
			}
			
			let greeting: String
			do {
				let tutorialCommitMessage = NSLocalizedString("tutorialCommitMessage", tableName: nil, comment: "")
				let tutorialWelcome = NSLocalizedString("tutorialWelcome", tableName: nil, comment: "")
				let tutorialShortcutsLabel = NSLocalizedString("tutorialShortcutsLabel", tableName: nil, comment: "")
				let tutorialCommitShortcut = NSLocalizedString("tutorialCommitShortcut", tableName: nil, comment: "")
				let tutorialCancelShortcut = NSLocalizedString("tutorialCancelShortcut", tableName: nil, comment: "")
				
				greeting = """
				\(tutorialCommitMessage)
				
				# \(tutorialWelcome)
				
				# \(tutorialShortcutsLabel)
				#    \(tutorialCommitShortcut)
				#    \(tutorialCancelShortcut)
				
				"""
			}
			
			let moveToApplicationsSuggestion: String
			do {
				let tutorialMoveAppSuggestion = NSLocalizedString("tutorialMoveAppSuggestion", tableName: nil, comment: "")
				
				moveToApplicationsSuggestion = """
				#
				# \(tutorialMoveAppSuggestion)
				# /Applications/
				
				"""
			}
			
			let editorPathToUse: String
			do {
				if !suggestMovingApp {
					editorPathToUse = executableURL.path
				} else {
					let mainBundlePathComponents = Bundle.main.bundleURL.pathComponents
					assert(executablePathComponents.count >= mainBundlePathComponents.count)
					
					let count = executablePathComponents.count - mainBundlePathComponents.count + 1
					let bundlePathComponents = executablePathComponents[executablePathComponents.count - count ..< executablePathComponents.count]
					
					let applicationsURL = URL(fileURLWithPath: "/Applications")
					editorPathToUse = applicationsURL.appendingPathComponent(bundlePathComponents.joined(separator: "/")).path
				}
			}
			
			let escapedEditorPathToUse =
				editorPathToUse
					.escapingGitConfigBreakingCharacters // escape for parsing by Git
					.doubleQuoteDelimited // escape for parsing by shell
			
			let editorConfigurationRecommendation: String
			do {
				let tutorialDefaultGitEditorRecommendation = NSLocalizedString("tutorialDefaultGitEditorRecommendation", tableName: nil, comment: "")
				let tutorialDefaultHgEditorRecommendation = NSLocalizedString("tutorialDefaultHgEditorRecommendation", tableName: nil, comment: "")
				let tutorialDefaultSvnEditorRecommendation = NSLocalizedString("tutorialDefaultSvnEditorRecommendation", tableName: nil, comment: "")
				let tutorialConsultEditorDocumentation = NSLocalizedString("tutorialConsultEditorDocumentation", tableName: nil, comment: "")
				let tutorialMoreThemes = NSLocalizedString("tutorialMoreThemes", tableName: nil, comment: "")
				let tutorialAutomaticUpdates = NSLocalizedString("tutorialAutomaticUpdates", tableName: nil, comment: "")
				
				editorConfigurationRecommendation = """
				#
				# \(tutorialDefaultGitEditorRecommendation)
				#
				# git config --global core.editor \(escapedEditorPathToUse)
				#
				# \(tutorialDefaultHgEditorRecommendation)
				# \(tutorialDefaultSvnEditorRecommendation)
				# \(tutorialConsultEditorDocumentation)
				#
				# \(tutorialMoreThemes)
				# \(tutorialAutomaticUpdates)
				"""
			}
			
			let intermediateMessage = suggestMovingApp ? greeting.appending(moveToApplicationsSuggestion) : greeting
			let finalMessage = intermediateMessage.appending(editorConfigurationRecommendation)
			
			// Write our commit file
			let localTempDirectoryURL: URL
			do {
				localTempDirectoryURL = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()), create: true)
				
				tempDirectoryURL = localTempDirectoryURL
			} catch {
				fatalError("Failed to create temp directory URL: \(error)")
			}
			
			let tutorialProjectFileName = NSLocalizedString("tutorialProjectFileName", tableName: nil, comment: "")
			commitFileURL = localTempDirectoryURL.appendingPathComponent(tutorialProjectFileName)
			
			do {
				try finalMessage.write(to: commitFileURL, atomically: false, encoding: .utf8)
			} catch {
				fatalError("Failed to write temporary greetings file with error \(error)")
			}
		}
		
		let editorWindowController = ZGEditorWindowController(fileURL: commitFileURL, temporaryDirectoryURL: tempDirectoryURL, tutorialMode: tutorialMode)
		self.editorWindowController = editorWindowController
		editorWindowController.showWindow(nil)
		
		updaterController = UpdaterController(checkForUpdatesProgressIndicator: editorWindowController.topBarViewController.checkForUpdatesProgressIndicator)
	}
	
	@objc func applicationWillTerminate(_ notification: Notification) {
		editorWindowController?.exit(success: false)
	}
	
	@objc @IBAction func showPreferences(_ sender: AnyObject) {
		if preferencesWindowController == nil,
		   let editorWindowController = editorWindowController,
		   let updaterController = updaterController {
			preferencesWindowController = ZGPreferencesWindowController(editorListener: editorWindowController, updaterListener: updaterController)
		}
		preferencesWindowController?.showWindow(nil)
	}
	
	@objc @IBAction func checkForUpdates(_ sender: AnyObject) {
		updaterController?.checkForUpdates()
	}
	
	@objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if menuItem.action == #selector(checkForUpdates(_:)) {
			return updaterController?.updater.canCheckForUpdates ?? false
		} else {
			return true
		}
	}
	
	@objc @IBAction func reportIssue(_ sender: AnyObject) {
		if let issuesURL = URL(string: "https://github.com/zorgiepoo/Komet/issues") {
			NSWorkspace.shared.open(issuesURL)
		}
	}
	
	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
}
