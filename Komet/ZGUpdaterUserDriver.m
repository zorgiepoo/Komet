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
	BOOL _userInitiatedUpdateCheck;
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

- (void)showUpdatePermissionRequest:(SPUUpdatePermissionRequest *)__unused request reply:(void (^)(SPUUpdatePermissionResponse *))reply
{
	// Our application is set to prompt the first time the updater starts, so we will just default to YES
	reply([[SPUUpdatePermissionResponse alloc] initWithAutomaticUpdateChecks:YES sendSystemProfile:NO]);
}

- (void)showUserInitiatedUpdateCheckWithCompletion:(void (^)(SPUUserInitiatedCheckStatus))updateCheckStatusCompletion
{
	_userInitiatedUpdateCheck = YES;
	[_coreComponent registerUpdateCheckStatusHandler:updateCheckStatusCompletion];
}

- (void)dismissUserInitiatedUpdateCheck
{
	[_coreComponent completeUpdateCheckStatus];
}

- (void)showUpdateFoundWithAppcastItem:(SUAppcastItem *)appcastItem reply:(void (^)(SPUUpdateAlertChoice))reply
{
	NSAlert *alert = [[NSAlert alloc] init];
	alert.alertStyle = NSInformationalAlertStyle;
	alert.informativeText = [NSString stringWithFormat:@"A new update (%@) is available. Would you like to download and install it after quitting Komet?", appcastItem.displayVersionString];
	alert.messageText = @"New Update";
	[alert addButtonWithTitle:@"Install on Quit"];
	[alert addButtonWithTitle:@"Cancel"];
	
	switch ([alert runModal])
	{
		case NSAlertFirstButtonReturn:
			reply(SPUInstallUpdateChoice);
			break;
		default:
			reply(SPUInstallLaterChoice);
			break;
	}
}

- (void)showDownloadedUpdateFoundWithAppcastItem:(SUAppcastItem *)__unused appcastItem reply:(void (^)(SPUUpdateAlertChoice))__unused reply
{
	// Nothing here for us to do; don't bug the user
	// We really should not get here because we disallow installer interaction though
}

- (void)showResumableUpdateFoundWithAppcastItem:(SUAppcastItem *)appcastItem reply:(void (^)(SPUInstallUpdateStatus))reply
{
	// Only bug the user if they were the ones that intiated an update check
	if (_userInitiatedUpdateCheck)
	{
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSInformationalAlertStyle;
		alert.informativeText = [NSString stringWithFormat:@"A new update (%@) is available, and will be installed after quitting Komet.", appcastItem.displayVersionString];
		alert.messageText = @"New Update";
		[alert addButtonWithTitle:@"OK"];
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
	alert.informativeText = [NSString stringWithFormat:@"You're up to date."];
	alert.messageText = @"No Update Available";
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	
	acknowledgement();
}

- (void)showUpdaterError:(NSError *)error acknowledgement:(void (^)(void))acknowledgement
{
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
	
	acknowledgement();
}

- (void)showDownloadInitiatedWithCompletion:(void (^)(SPUDownloadUpdateStatus))downloadUpdateStatusCompletion
{
	[_coreComponent registerDownloadStatusHandler:downloadUpdateStatusCompletion];
}

- (void)showDownloadDidReceiveExpectedContentLength:(NSUInteger)__unused expectedContentLength
{
}

- (void)showDownloadDidReceiveDataOfLength:(NSUInteger)__unused length
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
	_userInitiatedUpdateCheck = NO;
}

@end
