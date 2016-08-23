//
//  AppDelegate.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;
@import Darwin.sys.mount;

#import "ZGEditorWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
{
	ZGEditorWindowController *_editorWindowController;
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
	
	NSArray<NSString *> *arguments = [[NSProcessInfo processInfo] arguments];
	
	// The system can pass command line arguments unfortunately
	// So to distinguish between a user starting the app normally and a tool like git launching the app,
	// we should see detect if the exists
	NSURL *fileURL = nil;
	if (arguments.count >= 2)
	{
		fileURL = [NSURL fileURLWithPath:arguments[1]];
	}
	
	BOOL tutorialMode = NO;
	if (fileURL == nil || ![fileURL checkResourceIsReachableAndReturnError:NULL])
	{
		tutorialMode = YES;
		
		NSString *executablePath = [[NSBundle mainBundle] executablePath];
		
		NSString *appName = [[NSRunningApplication currentApplication] localizedName];
		
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
		 @"Add tutorial to %@\n"
		 @"\n"
		 @"Todo: Add UI for Preferences, and make other improvements.\n"
		 @"\n"
		 @"# Welcome to the Cocoa commit editor for macOS.\n"
		 @"#\n"
		 @"# Useful shortcuts:\n"
		 @"#    Commit: ⌘return\n"
		 @"#    Cancel: ⌘Q\n", appName];
		
		NSString *moveToApplicationsSuggestion =
		[NSString stringWithFormat:
		 @"#\n"
		 @"# You should first move %@ to somewhere persistent like\n"
		 @"# /Applications/\n", appName];
		
		NSArray<NSString *> *mainBundlePathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
		
		assert(executablePathComponents.count >= mainBundlePathComponents.count);
		NSUInteger count = executablePathComponents.count - mainBundlePathComponents.count + 1;
		NSArray<NSString *> *bundlePathComponents = [executablePathComponents subarrayWithRange:NSMakeRange(executablePathComponents.count - count, count)];
		
		NSString *editorPathToUse = suggestMovingApp ? [@"/Applications" stringByAppendingPathComponent:[bundlePathComponents componentsJoinedByString:@"/"]] : executablePath;
		
		NSString *editorConfigurationRecommendation =
		[NSString stringWithFormat:
		 @"#\n"
		 @"# You may want to set %@ as your default git editor:\n"
		 @"#\n"
		 @"# git config --global core.editor \"%@\"\n"
		 @"#\n"
		 @"# For hg, you will want to set the HGEDITOR environment variable.\n"
		 @"# For svn, you will want to set the SVN_EDITOR environment variable.\n"
		 @"# Please consult their documentation for more information.\n", appName, editorPathToUse];
		
		NSString *finalMessage = greeting;
		if (suggestMovingApp)
		{
			finalMessage = [finalMessage stringByAppendingString:moveToApplicationsSuggestion];
		}
		
		finalMessage = [finalMessage stringByAppendingString:editorConfigurationRecommendation];
		
		NSError *temporaryError = nil;
		NSURL *tempDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:[NSURL fileURLWithPath:NSTemporaryDirectory()] create:YES error:&temporaryError];
		
		if (tempDirectoryURL == nil)
		{
			fprintf(stderr, "Failed to create temp directory because of error: %s\n", temporaryError.localizedDescription.UTF8String);
			exit(EXIT_FAILURE);
		}
		
		// Write our commit file
		NSError *writeError = nil;
		fileURL = [tempDirectoryURL URLByAppendingPathComponent:@"Tutorial"];
		if (![finalMessage writeToURL:fileURL atomically:NO encoding:NSUTF8StringEncoding error:&writeError])
		{
			fprintf(stderr, "Failed to create temporary greetings file with error: %s\n", writeError.localizedDescription.UTF8String);
			exit(EXIT_FAILURE);
		}
	}
	
	_editorWindowController = [[ZGEditorWindowController alloc] initWithFileURL:fileURL tutorialMode:tutorialMode];
	[_editorWindowController showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)__unused notification
{
	[_editorWindowController exitWithSuccess:NO];
}

@end
