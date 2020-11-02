//
//  UpdaterController.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/1/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Foundation

@objc class ZGUpdaterDelegate: NSObject, SPUUpdaterDelegate {
	func updater(_ updater: SPUUpdater, shouldAllowInstallerInteractionFor updateCheck: SPUUpdateCheck) -> Bool {
		switch updateCheck {
		case .userInitiated:
			return true
		case .backgroundScheduled:
			return false
		@unknown default:
			print("Encountered unknown update check")
			return false
		}
	}
	
	func updaterShouldDownloadReleaseNotes(_ updater: SPUUpdater) -> Bool {
		return false
	}
}

@objc class ZGUpdaterController: NSObject, ZGUpdaterSettingsListener {
	let updater: SPUUpdater
	let userDriver: ZGUpdaterUserDriver
	let updaterDelegate: SPUUpdaterDelegate
	let startedUpdater: Bool
	
	override init() {
		let mainBundle = Bundle.main
		
		userDriver = ZGUpdaterUserDriver()
		
		updaterDelegate = ZGUpdaterDelegate()
		updater = SPUUpdater(hostBundle: mainBundle, applicationBundle: mainBundle, userDriver: userDriver, delegate: updaterDelegate)
		
		updater.automaticallyDownloadsUpdates = true
		
		do {
			try updater.start()
			startedUpdater = true
		} catch {
			startedUpdater = false
			print("Error: Failed to start updater because of error: \(error)")
		}
		
		super.init()
	}
	
	var canCheckForUpdates: Bool {
		get {
			return startedUpdater && userDriver.canCheckForUpdates
		}
	}
	
	func checkForUpdates() {
		if startedUpdater {
			updater.checkForUpdates()
		}
	}
	
	func updaterSettingsChangedAutomaticallyInstallingUpdates(_ automaticallyInstallUpdates: Bool) {
		updater.automaticallyChecksForUpdates = automaticallyInstallUpdates
	}
}
