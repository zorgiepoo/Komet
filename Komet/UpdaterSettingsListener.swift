//
//  UpdaterSettingsListener.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/1/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

protocol UpdaterSettingsListener: AnyObject {
	func updaterSettingsChangedAutomaticallyInstallingUpdates(_ automaticallyInstallUpdates: Bool)
	
	func updaterSettingsChangedAllowingBetaUpdates()
}
