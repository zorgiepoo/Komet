//
//  UpdaterUserDriver.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/6/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Cocoa
import Sparkle

@objc class ZGUpdaterUserDriver: NSObject, SPUUserDriver {
	func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
		// Our application is not set to prompt, but just reply anyway
		reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
	}
	
	func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
		// Ideally we should show progress but do nothing for now
	}
	
	private func promptUpdate(userInitiated: Bool, informativeText: String, stage: SPUUserUpdateStage, response: (SPUUserUpdateChoice) -> ()) {
		// Only bug the user if they were the ones that intiated an update check
		if userInitiated {
			// We only give the user an option to install the update on quit, or to cancel/defer
			let alert = NSAlert()
			alert.alertStyle = .informational
			alert.informativeText = informativeText
			alert.messageText = NSLocalizedString("updaterNewUpdateAlert", tableName: nil, comment: "")
			alert.addButton(withTitle: NSLocalizedString("updaterInstallOnQuit", tableName: nil, comment: ""))
			alert.addButton(withTitle: NSLocalizedString("updaterCancel", tableName: nil, comment: ""))
			
			switch alert.runModal() {
			case .alertFirstButtonReturn:
				if stage == .installing {
					// Defer installing/relaunching the update until quit
					response(.dismiss)
				} else {
					// Begin installation. Later when are ready to relaunch, we will defer the update
					response(.install)
				}
			default:
				response(.dismiss)
			}
		} else {
			response(.dismiss)
		}
	}
	
	func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping (SPUUserUpdateChoice) -> Void) {
		if appcastItem.isInformationOnlyUpdate {
			if let infoURL = appcastItem.infoURL, state.userInitiated {
				NSWorkspace.shared.open(infoURL)
			}
			
			reply(.dismiss)
		} else {
			let newUpdateLocalizedKey: String
			switch state.stage {
			case .notDownloaded:
				newUpdateLocalizedKey = "updaterNewUpdateAvailableFormat"
			case .downloaded:
				newUpdateLocalizedKey = "updaterNewUpdateDownloadedFormat"
			case .installing:
				newUpdateLocalizedKey = "updaterNewUpdateResumableFormat"
			@unknown default:
				newUpdateLocalizedKey = "updaterNewUpdateAvailableFormat"
			}
			
			let informativeText = String(format: NSLocalizedString(newUpdateLocalizedKey, tableName: nil, comment: ""), appcastItem.displayVersionString)
			
			promptUpdate(userInitiated: state.userInitiated, informativeText: informativeText, stage: state.stage, response: reply)
		}
	}
	
	func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
		// Do nothing
	}
	
	func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
		// Do nothing
	}
	
	func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.informativeText = NSLocalizedString("updaterLatestVersionInstalled", tableName: nil, comment: "")
		alert.messageText = NSLocalizedString("updaterNoUpdateAvailable", tableName: nil, comment: "")
		alert.addButton(withTitle: NSLocalizedString("updaterOK", tableName: nil, comment: ""))
		alert.runModal()
		
		acknowledgement()
	}
	
	func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
		let alert = NSAlert(error: error)
		alert.runModal()
		
		acknowledgement()
	}
	
	func showDownloadInitiated(cancellation: @escaping () -> Void) {
		// Do nothing
	}
	
	func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
		// Do nothing
	}
	
	func showDownloadDidReceiveData(ofLength length: UInt64) {
		// Do nothing
	}
	
	func showDownloadDidStartExtractingUpdate() {
		// Do nothing
	}
	
	func showExtractionReceivedProgress(_ progress: Double) {
		// Do nothing
	}
	
	func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) {
		// Do nothing
	}
	
	func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
		// Defer the update
		reply(.dismiss)
	}
	
	func showSendingTerminationSignal() {
		// Do nothing
	}
	
	func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
		acknowledgement()
	}
	
	func showUpdateInFocus() {
		// No need to do anything
	}
	
	func dismissUpdateInstallation() {
		// No need to do anything
	}
	
}
