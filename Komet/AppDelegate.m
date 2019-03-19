//
//  AppDelegate.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;
@import Darwin.sys.mount;
@import ObjectiveC.runtime;

#import "ZGEditorWindowController.h"
#import "ZGPreferencesWindowController.h"
#import "ZGUpdaterController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
{
	ZGEditorWindowController *_editorWindowController;
	ZGPreferencesWindowController *_preferencesWondowController;
	ZGUpdaterController *_updaterController;
}

- (BOOL)pathComponents:(NSArray<NSString *> *)pathComponents isSubsetOfPathComponents:(NSArray<NSString *> *)parentPathComponents
{
	if (pathComponents == nil || parentPathComponents == nil || pathComponents.count > parentPathComponents.count)
	{
		return NO;
	}
	
	return [[parentPathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count)] isEqualToArray:pathComponents];
}

- (void)applicationDidFinishLaunching:(NSNotification *)__unused aNotification
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
	// This is the Apple recommended way of checking if touch bar functionality is available
	// because there are two different 10.12.1 builds that were publicly released; one of them
	// has touch bar functionality, and the other one doesn't
	if (NSClassFromString(@"NSTouchBar") != nil)
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
		[[NSApplication sharedApplication] setAutomaticCustomizeTouchBarMenuItemEnabled:YES];
#pragma clang diagnostic pop
	}
	
	NSArray<NSString *> *arguments = [[NSProcessInfo processInfo] arguments];
	
	// The system can pass command line arguments unfortunately
	// So to distinguish between a user starting the app normally and a tool like git launching the app,
	// we should see detect if the file exists
	NSURL *fileURL = nil;
	if (arguments.count >= 2)
	{
		fileURL = [NSURL fileURLWithPath:arguments[1]];
	}
	
	NSURL *tempDirectoryURL = nil;
	BOOL tutorialMode = NO;
	if (fileURL == nil || ![fileURL checkResourceIsReachableAndReturnError:NULL])
	{
		tutorialMode = YES;
		
		NSString *executablePath = [[NSBundle mainBundle] executablePath];
		
		BOOL suggestMovingApp = NO;
		
		NSArray<NSString *> *executablePathComponents = executablePath.pathComponents;
		
		struct statfs statInfo;
		if (statfs(executablePath.fileSystemRepresentation, &statInfo) == 0 && (statInfo.f_flags & MNT_RDONLY) != 0)
		{
			suggestMovingApp = YES;
		}
		else
		{
			NSFileManager *fileManager = [[NSFileManager alloc] init];
			
			NSURL *downloadsURL = [fileManager URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
			
			NSURL *desktopURL = [fileManager URLForDirectory:NSDesktopDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
			
			NSURL *developerLibraryURL = [[fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL] URLByAppendingPathComponent:@"Developer"];
			
			if ([self pathComponents:downloadsURL.pathComponents isSubsetOfPathComponents:executablePathComponents] || [self pathComponents:desktopURL.pathComponents isSubsetOfPathComponents:executablePathComponents] || [self pathComponents:developerLibraryURL.pathComponents isSubsetOfPathComponents:executablePathComponents])
			{
				suggestMovingApp = YES;
			}
		}
		
		NSString *greeting =
		[NSString stringWithFormat:
		 @"%@\n"
		 @"\n"
		 @"# %@\n"
		 @"#\n"
		 @"# %@\n"
		 @"#    %@\n"
		 @"#    %@\n",
		 NSLocalizedString(@"tutorialCommitMessage", nil),
		 NSLocalizedString(@"tutorialWelcome", nil),
		 NSLocalizedString(@"tutorialShortcutsLabel", nil),
		 NSLocalizedString(@"tutorialCommitShortcut", nil),
		 NSLocalizedString(@"tutorialCancelShortcut", nil)];
		
		NSString *moveToApplicationsSuggestion =
		[NSString stringWithFormat:
		 @"#\n"
		 @"# %@\n"
		 @"# /Applications/\n",
		 NSLocalizedString(@"tutorialMoveAppSuggestion", nil)];
		
		NSArray<NSString *> *mainBundlePathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
		
		assert(executablePathComponents.count >= mainBundlePathComponents.count);
		NSUInteger count = executablePathComponents.count - mainBundlePathComponents.count + 1;
		NSArray<NSString *> *bundlePathComponents = [executablePathComponents subarrayWithRange:NSMakeRange(executablePathComponents.count - count, count)];
		
		NSString *editorPathToUse = suggestMovingApp ? [@"/Applications" stringByAppendingPathComponent:[bundlePathComponents componentsJoinedByString:@"/"]] : executablePath;
		
		NSString *editorConfigurationRecommendation =
		[NSString stringWithFormat:
		 @"#\n"
		 @"# %@\n"
		 @"#\n"
		 @"# git config --global core.editor \"%@\"\n"
		 @"#\n"
		 @"# %@\n"
		 @"# %@\n"
		 @"# %@\n"
		 @"#\n"
		 @"# %@\n"
		 @"# %@\n",
		 NSLocalizedString(@"tutorialDefaultGitEditorRecommendation", nil),
		 editorPathToUse,
		 NSLocalizedString(@"tutorialDefaultHgEditorRecommendation", nil),
		 NSLocalizedString(@"tutorialDefaultSvnEditorRecommendation", nil),
		 NSLocalizedString(@"tutorialConsultEditorDocumentation", nil),
		 NSLocalizedString(@"tutorialMoreThemes", nil),
		 NSLocalizedString(@"tutorialAutomaticUpdates", nil)];
		
		NSString *finalMessage = greeting;
		if (suggestMovingApp)
		{
			finalMessage = [finalMessage stringByAppendingString:moveToApplicationsSuggestion];
		}
		
		finalMessage = [finalMessage stringByAppendingString:editorConfigurationRecommendation];
		
		NSError *temporaryError = nil;
		tempDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:[NSURL fileURLWithPath:NSTemporaryDirectory()] create:YES error:&temporaryError];
		
		if (tempDirectoryURL == nil)
		{
			NSLog(@"Failed to create temp directory because of error: %@",  temporaryError.localizedDescription);
			exit(EXIT_FAILURE);
		}
		
		// Write our commit file
		NSError *writeError = nil;
		fileURL = [tempDirectoryURL URLByAppendingPathComponent:NSLocalizedString(@"tutorialProjectFileName", nil)];
		if (![finalMessage writeToURL:fileURL atomically:NO encoding:NSUTF8StringEncoding error:&writeError])
		{
			NSLog(@"Failed to create temporary greetings file with error: %@",  writeError.localizedDescription);
			exit(EXIT_FAILURE);
		}
	}
	
	_editorWindowController = [[ZGEditorWindowController alloc] initWithFileURL:fileURL temporaryDirectoryURL:tempDirectoryURL tutorialMode:tutorialMode];
	[_editorWindowController showWindow:nil];
	
	_updaterController = [[ZGUpdaterController alloc] init];
}

- (void)applicationWillTerminate:(NSNotification *)__unused notification
{
	[_editorWindowController exitWithSuccess:NO];
}

- (IBAction)showPreferences:(id)__unused sender
{
	if (_preferencesWondowController == nil)
	{
		_preferencesWondowController = [[ZGPreferencesWindowController alloc] initWithEditorListener:_editorWindowController updaterListener:_updaterController];
	}
	[_preferencesWondowController showWindow:nil];
}

- (IBAction)checkForUpdates:(id)__unused sender
{
	[_updaterController checkForUpdates];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(checkForUpdates:))
	{
		return _updaterController.canCheckForUpdates;
	}
	return YES;
}

- (IBAction)reportIssue:(id)__unused sender
{
	NSURL *issuesURL = [NSURL URLWithString:@"https://github.com/zorgiepoo/Komet/issues"];
	if (issuesURL != nil)
	{
		[[NSWorkspace sharedWorkspace] openURL:issuesURL];
	}
}

@end
