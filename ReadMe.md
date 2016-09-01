# Komet

A Cocoa text editor designed for creating commit messages.

![Image of Komet](Screenshot.png)

## Purpose

I do version control from the command line but I want a native, fast, and non-obstructive editor for creating commit messages. Not being stuck in a save-and-close model, applying a commit takes only *one* action in Komet.

I also want features such as spell checking and automatic correction that are expected to be available in Cocoa applications.

## Requirements

**System Version**: macOS 10.10 or later

**Supported Version Control**: git, hg, svn

Systems prior to macOS 10.10 cannot run Komet due to some appearance settings that are used.

For optimal behavior, Komet depends on being able to distinguish the commit message content and the comment section that extends to the end of the file. Thus, Komet has a small bit of code for handling each of the supported version control systems.

## Contributing

If you enjoy using it and feel like something could improve, feel free to make a contribution. It is advisable to create an issue first before submitting a big change. Please also read and follow the code of conduct in the repository first before contributing.

As for one area of improvement may be enhancing the user interface. I'm no expert in UI myself and received a lot of help with the current interface.
