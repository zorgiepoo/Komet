//
//  ZGUpdaterController.m
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGUpdaterController.h"
#import "ZGUpdaterUserDriver.h"

@implementation ZGUpdaterController
{
	SPUUpdater *_updater;
	ZGUpdaterUserDriver *_userDriver;
	BOOL _startedUpdater;
}

- (instancetype)init
{
	self = [super init];
	if (self != nil)
	{
		NSBundle *mainBundle = [NSBundle mainBundle];
		_userDriver = [[ZGUpdaterUserDriver alloc] init];
		_updater = [[SPUUpdater alloc] initWithHostBundle:mainBundle applicationBundle:mainBundle userDriver:_userDriver delegate:self];
		
		_updater.automaticallyDownloadsUpdates = YES;
		
		NSError *updateError = nil;
		_startedUpdater = [_updater startUpdater:&updateError];
		if (!_startedUpdater)
		{
			// We still want the application to otherwise work, so we won't abort
			NSLog(@"Error: Failed to start updater because of error: %@", updateError);
		}
	}
	return self;
}

- (BOOL)updater:(SPUUpdater *)__unused updater shouldAllowInstallerInteractionForUpdateCheck:(SPUUpdateCheck)updateCheck
{
	switch (updateCheck)
	{
		case SPUUpdateCheckUserInitiated:
			return YES;
		case SPUUpdateCheckBackgroundScheduled:
			return NO;
	}
}

- (BOOL)updaterShouldDownloadReleaseNotes:(SPUUpdater *)__unused updater
{
	return NO;
}

- (BOOL)canCheckForUpdates
{
	return (_startedUpdater && _userDriver.canCheckForUpdates);
}

- (void)checkForUpdates
{
	if (_startedUpdater)
	{
		[_updater checkForUpdates];
	}
}

- (void)updaterSettingsChangedAutomaticallyInstallingUpdates:(BOOL)automaticallyInstallUpdates
{
	_updater.automaticallyChecksForUpdates = automaticallyInstallUpdates;
}

@end
