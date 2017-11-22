//
//  main.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

int main(int argc, const char * argv[])
{
#ifndef DEBUG
	// Redirect stderr and stdout to /dev/null only if we're not running in DEBUG
	// So if we or AppKit ever try to call NSLog, this will not bug the user in their Terminal for Release builds
	// Though the message/error should still be reported and visible in Console.app
	int devNull = open("/dev/null", O_WRONLY);
	
	dup2(devNull, STDERR_FILENO);
	dup2(devNull, STDOUT_FILENO);
	
	close(devNull);
#endif
	
	return NSApplicationMain(argc, argv);
}
