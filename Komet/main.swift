//
//  main.swift
//  Komet
//
//  Created by Mayur Pawashe on 11/6/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import Cocoa

#if !DEBUG
// Redirect stderr and stdout to /dev/null only if we're not running in DEBUG
// So if we or AppKit ever try to call NSLog() or print(), this will not bug the user in their session for Release builds
// Though logging message/error may still be reported elsewhere in the system
let devNull = open("/dev/null", O_WRONLY);

dup2(devNull, STDERR_FILENO);
dup2(devNull, STDOUT_FILENO);

close(devNull);
#endif

let _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
