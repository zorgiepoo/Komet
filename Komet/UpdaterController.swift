//
//  UpdaterController.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/1/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Foundation
import Sparkle

private let KOMET_ERROR_DOMAIN = "KometErrorDomain"
private let USER_AUTHORIZATION_ERROR_CODE = 1

@objc class ZGUpdaterDelegate: NSObject, SPUUpdaterDelegate {
	func updater(_ updater: SPUUpdater, shouldDownloadReleaseNotesForUpdate updateItem: SUAppcastItem) -> Bool {
		return false
	}
	
	func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
		switch updateCheck {
		case .updates:
			break
		case .updatesInBackground:
			let mainBundlePath = Bundle.main.bundlePath
			if SPUSystemNeedsAuthorizationAccessForBundlePath(mainBundlePath) {
				throw NSError(domain: KOMET_ERROR_DOMAIN, code: USER_AUTHORIZATION_ERROR_CODE, userInfo: [NSLocalizedDescriptionKey: "Updates that require user authorization cannot be installed in the background."])
			}
			break
		case .updateInformation:
			break
		@unknown default:
			break
		}
	}
	
	func allowedChannels(for updater: SPUUpdater) -> Set<String> {
		let betaUpdatesEnabled = UserDefaults.standard.bool(forKey: ZGEnableBetaUpdatesKey)
		return betaUpdatesEnabled ? ["beta"] : []
	}
}

class UpdaterController: UpdaterSettingsListener {
	let updater: SPUUpdater
	let userDriver: ZGUpdaterUserDriver
	let updaterDelegate: SPUUpdaterDelegate
	
	init() {
		let mainBundle = Bundle.main
		
		userDriver = ZGUpdaterUserDriver()
		
		updaterDelegate = ZGUpdaterDelegate()
		updater = SPUUpdater(hostBundle: mainBundle, applicationBundle: mainBundle, userDriver: userDriver, delegate: updaterDelegate)
		
		// This is set in the Info.plist instead now
		//updater.automaticallyDownloadsUpdates = true
		
		do {
			try updater.start()
		} catch {
			print("Error: Failed to start updater because of error: \(error)")
		}
	}
	
	func checkForUpdates() {
		updater.checkForUpdates()
	}
	
	func updaterSettingsChangedAutomaticallyInstallingUpdates(_ automaticallyInstallUpdates: Bool) {
		updater.automaticallyChecksForUpdates = automaticallyInstallUpdates
	}
	
	func updaterSettingsChangedAllowingBetaUpdates() {
		updater.resetUpdateCycleAfterShortDelay()
	}
}
