//
//  ZGUpdaterUserDriver.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGUpdaterUserDriver.h"

@implementation ZGUpdaterUserDriver
{
	SPUUserDriverCoreComponent *_coreComponent;
}

- (instancetype)init
{
	self = [super init];
	if (self != nil)
	{
		_coreComponent = [[SPUUserDriverCoreComponent alloc] init];
	}
	return self;
}

- (void)showCanCheckForUpdates:(BOOL)canCheckForUpdates
{
	_canCheckForUpdates = canCheckForUpdates;
}

- (void)showUpdatePermissionRequest:(SPUUpdatePermissionRequest *)__unused request reply:(void (^)(SUUpdatePermissionResponse *))reply
{
	// Our application is set to prompt the first time the updater starts, so we will just default to YES
	reply([[SUUpdatePermissionResponse alloc] initWithAutomaticUpdateChecks:YES sendSystemProfile:NO]);
}

- (void)showUserInitiatedUpdateCheckWithCompletion:(void (^)(SPUUserInitiatedCheckStatus))updateCheckStatusCompletion
{
	[_coreComponent registerUpdateCheckStatusHandler:updateCheckStatusCompletion];
}

- (void)dismissUserInitiatedUpdateCheck
{
	[_coreComponent completeUpdateCheckStatus];
}

- (void)promptUserInitiatedCheck:(BOOL)userInitiatedCheck withInformativeText:(NSString *)informativeText response:(void (^)(SPUUpdateAlertChoice))response
{
	// Only bug the user if they were the ones that intiated an update check
	if (userInitiatedCheck)
	{
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSInformationalAlertStyle;
		alert.informativeText = informativeText;
		alert.messageText = NSLocalizedString(@"updaterNewUpdateAlert", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"updaterInstallOnQuit", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"updaterCancel", nil)];
		
		NSModalResponse modalResponse = [alert runModal];
		if (modalResponse == NSAlertFirstButtonReturn)
		{
			response(SPUInstallUpdateChoice);
		}
		else
		{
			response(SPUInstallLaterChoice);
		}
	}
	else
	{
		response(SPUInstallLaterChoice);
	}
}

- (void)showUpdateFoundWithAppcastItem:(SUAppcastItem *)appcastItem userInitiated:(BOOL)userInitiated reply:(void (^)(SPUUpdateAlertChoice))reply
{
	NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"updaterNewUpdateAvailableFormat", nil), appcastItem.displayVersionString];
	
	[self promptUserInitiatedCheck:userInitiated withInformativeText:informativeText response:reply];
}

- (void)showDownloadedUpdateFoundWithAppcastItem:(SUAppcastItem *)appcastItem userInitiated:(BOOL)userInitiated reply:(void (^)(SPUUpdateAlertChoice))reply
{
	// It should be very unlikely that we reach this method but we may as well handle it
	// (because the update would have to be downloaded in the background, and not able to have permission to start the installer, but we disallow updating if such interaction is necessary..)
	
	NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"updaterNewUpdateDownloadedFormat", nil), appcastItem.displayVersionString];
	
	[self promptUserInitiatedCheck:userInitiated withInformativeText:informativeText response:reply];
}

- (void)showResumableUpdateFoundWithAppcastItem:(SUAppcastItem *)appcastItem userInitiated:(BOOL)userInitiated reply:(void (^)(SPUInstallUpdateStatus))reply
{
	// Only bug the user if they were the ones that intiated an update check
	if (userInitiated)
	{
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSInformationalAlertStyle;
		alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"updaterNewUpdateResumableFormat", nil), appcastItem.displayVersionString];
		alert.messageText = NSLocalizedString(@"updaterNewUpdateAlert", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"updaterOK", nil)];
		[alert runModal];
	}
	reply(SPUDismissUpdateInstallation);
}

- (void)showUpdateReleaseNotesWithDownloadData:(SPUDownloadData *)__unused downloadData
{
}

- (void)showUpdateReleaseNotesFailedToDownloadWithError:(NSError *)__unused error
{
}

- (void)showUpdateNotFoundWithAcknowledgement:(void (^)(void))acknowledgement
{
	NSAlert *alert = [[NSAlert alloc] init];
	alert.alertStyle = NSInformationalAlertStyle;
	alert.informativeText = NSLocalizedString(@"updaterLatestVersionInstalled", nil);
	alert.messageText = NSLocalizedString(@"updaterNoUpdateAvailable", nil);
	[alert addButtonWithTitle:NSLocalizedString(@"updaterOK", nil)];
	[alert runModal];
	
	acknowledgement();
}

- (void)showUpdaterError:(NSError *)error acknowledgement:(void (^)(void))acknowledgement
{
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
	
	acknowledgement();
}

- (void)showInformationalUpdateFoundWithAppcastItem:(nonnull SUAppcastItem *)appcastItem userInitiated:(BOOL)userInitiated reply:(nonnull void (^)(SPUInformationalUpdateAlertChoice))reply
{
	if (userInitiated)
	{
		[[NSWorkspace sharedWorkspace] openURL:appcastItem.infoURL];
	}
	
	reply(SPUDismissInformationalNoticeChoice);
}

- (void)showDownloadInitiatedWithCompletion:(void (^)(SPUDownloadUpdateStatus))downloadUpdateStatusCompletion
{
	[_coreComponent registerDownloadStatusHandler:downloadUpdateStatusCompletion];
}

- (void)showDownloadDidReceiveExpectedContentLength:(uint64_t)__unused expectedContentLength
{
}

- (void)showDownloadDidReceiveDataOfLength:(uint64_t)__unused length
{
}

- (void)showDownloadDidStartExtractingUpdate
{
	[_coreComponent completeDownloadStatus];
}

- (void)showExtractionReceivedProgress:(double)__unused progress
{
}

- (void)showReadyToInstallAndRelaunch:(void (^)(SPUInstallUpdateStatus))__unused installUpdateHandler
{
	// Don't make a reply - if we do, the user can check/resume for updates again and there's no need for that
}

- (void)showInstallingUpdate
{
}

- (void)showSendingTerminationSignal
{
}

- (void)showUpdateInstallationDidFinishWithAcknowledgement:(void (^)(void))acknowledgement
{
	acknowledgement();
}

- (void)dismissUpdateInstallation
{
}

@end
