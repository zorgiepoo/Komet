//
//  UpdaterUserDriver.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/6/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Cocoa

@objc class ZGUpdaterUserDriver: NSObject, SPUUserDriver {
	private let coreComponent = SPUUserDriverCoreComponent()
	private var _canCheckForUpdates: Bool = false
	
	var canCheckForUpdates: Bool {
		get {
			return _canCheckForUpdates
		}
	}
	
	func showCanCheck(forUpdates canCheckForUpdates: Bool) {
		_canCheckForUpdates = canCheckForUpdates
	}
	
	func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
		// Our application is set to prompt the first time the updater starts, so we will just default to YES
		reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
	}
	
	func showUserInitiatedUpdateCheck(completion updateCheckStatusCompletion: @escaping (SPUUserInitiatedCheckStatus) -> Void) {
		coreComponent.registerUpdateCheckStatusHandler(updateCheckStatusCompletion)
	}
	
	func dismissUserInitiatedUpdateCheck() {
		coreComponent.completeUpdateCheckStatus()
	}
	
	private func promptUpdate(userInitiated: Bool, informativeText: String, response: (SPUUpdateAlertChoice) -> ()) {
		// Only bug the user if they were the ones that intiated an update check
		if userInitiated {
			let alert = NSAlert()
			alert.alertStyle = .informational
			alert.informativeText = informativeText
			alert.messageText = NSLocalizedString("updaterNewUpdateAlert", tableName: nil, comment: "")
			alert.addButton(withTitle: NSLocalizedString("updaterInstallOnQuit", tableName: nil, comment: ""))
			alert.addButton(withTitle: NSLocalizedString("updaterCancel", tableName: nil, comment: ""))
			
			switch alert.runModal() {
			case .alertFirstButtonReturn:
				response(.installUpdateChoice)
			default:
				response(.installLaterChoice)
			}
		} else {
			response(.installLaterChoice)
		}
	}
	
	func showUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUUpdateAlertChoice) -> Void) {
		let informativeText = String(format: NSLocalizedString("updaterNewUpdateAvailableFormat", tableName: nil, comment: ""), appcastItem.displayVersionString)
		promptUpdate(userInitiated: userInitiated, informativeText: informativeText, response: reply)
	}
	
	func showDownloadedUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUUpdateAlertChoice) -> Void) {
		// It should be very unlikely that we reach this method but we may as well handle it
		// (because the update would have to be downloaded in the background, and not able to have permission to start the installer, but we disallow updating if such interaction is necessary..)
		
		let informativeText = String(format: NSLocalizedString("updaterNewUpdateDownloadedFormat", tableName: nil, comment: ""), appcastItem.displayVersionString)
		promptUpdate(userInitiated: userInitiated, informativeText: informativeText, response: reply)
	}
	
	func showResumableUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUInstallUpdateStatus) -> Void) {
		// Only bug the user if they were the ones that intiated an update check
		if userInitiated {
			let alert = NSAlert()
			alert.alertStyle = .informational
			alert.informativeText = String(format: NSLocalizedString("updaterNewUpdateResumableFormat", tableName: nil, comment: ""), appcastItem.displayVersionString)
			alert.messageText = NSLocalizedString("updaterNewUpdateAlert", tableName: nil, comment: "")
			alert.addButton(withTitle: NSLocalizedString("updaterOK", tableName: nil, comment: ""))
			alert.runModal()
		}
	}
	
	func showInformationalUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUInformationalUpdateAlertChoice) -> Void) {
		if userInitiated {
			NSWorkspace.shared.open(appcastItem.infoURL)
		}
		
		reply(.dismissInformationalNoticeChoice)
	}
	
	func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
	}
	
	func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
	}
	
	func showUpdateNotFound(acknowledgement: @escaping () -> Void) {
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.informativeText = NSLocalizedString("updaterLatestVersionInstalled", tableName: nil, comment: "")
		alert.messageText = NSLocalizedString("updaterNoUpdateAvailable", tableName: nil, comment: "")
		alert.addButton(withTitle: NSLocalizedString("updaterOK", tableName: nil, comment: ""))
		alert.runModal()
		
		acknowledgement()
	}
	
	func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
		let alert = NSAlert()
		alert.runModal()
		
		acknowledgement()
	}
	
	func showDownloadInitiated(completion downloadUpdateStatusCompletion: @escaping (SPUDownloadUpdateStatus) -> Void) {
		coreComponent.registerDownloadStatusHandler(downloadUpdateStatusCompletion)
	}
	
	func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
	}
	
	func showDownloadDidReceiveData(ofLength length: UInt64) {
	}
	
	func showDownloadDidStartExtractingUpdate() {
		coreComponent.completeDownloadStatus()
	}
	
	func showExtractionReceivedProgress(_ progress: Double) {
	}
	
	func showReady(toInstallAndRelaunch installUpdateHandler: @escaping (SPUInstallUpdateStatus) -> Void) {
		// Don't make a reply - if we do, the user can check/resume for updates again and there's no need for that
	}
	
	func showInstallingUpdate() {
	}
	
	func showSendingTerminationSignal() {
	}
	
	func showUpdateInstallationDidFinish(acknowledgement: @escaping () -> Void) {
		acknowledgement()
	}
	
	func dismissUpdateInstallation() {
	}
}
