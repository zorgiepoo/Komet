//
//  ZGEditorWindowController.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGEditorWindowController.h"
#import "ZGCommitTextView.h"
#import "ZGUserDefaults.h"
#import "ZGWindowStyle.h"

#define ZGEditorWindowFrameNameKey @"ZGEditorWindowFrame"

typedef NS_ENUM(NSUInteger, ZGVersionControlType)
{
	ZGVersionControlGit,
	ZGVersionControlHg,
	ZGVersionControlSvn
};

@interface ZGEditorWindowController () <NSTextStorageDelegate, NSLayoutManagerDelegate, NSTextViewDelegate, ZGCommitViewDelegate>
@end

@implementation ZGEditorWindowController
{
	NSURL *_fileURL;
	IBOutlet NSView *_topBar;
	IBOutlet NSBox *_horizontalBarDivider;
	IBOutlet ZGCommitTextView *_textView;
	IBOutlet NSScrollView *_scrollView;
	IBOutlet NSVisualEffectView *_contentView;
	IBOutlet NSTextField *_commitLabelTextField;
	IBOutlet NSButtonCell *_cancelButton;
	IBOutlet NSButton *_commitButton;
	BOOL _preventAccidentalNewline;
	BOOL _initiallyContainedEmptyContent;
	BOOL _tutorialMode;
	NSUInteger _commentSectionLength;
	ZGVersionControlType _versionControlType;
	ZGWindowStyle *_style;
}

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		ZGRegisterDefaultMessageFont();
		ZGRegisterDefaultCommentsFont();
		ZGRegisterDefaultRecommendedSubjectLengthLimitEnabled();
		ZGRegisterDefaultRecommendedSubjectLengthLimit();
		ZGRegisterDefaultRecommendedBodyLineLengthLimitEnabled();
		ZGRegisterDefaultRecommendedBodyLineLengthLimit();
		ZGRegisterDefaultAutomaticNewlineInsertionAfterSubjectLine();
		ZGRegisterDefaultWindowStyleTheme();
		ZGRegisterDefaultEnableAutomaticSpellingCorrection();
	});
}

- (instancetype)initWithFileURL:(NSURL *)fileURL tutorialMode:(BOOL)tutorialMode
{
	self = [super init];
	if (self != nil)
	{
		_fileURL = fileURL;
		_tutorialMode = tutorialMode;
	}
	return self;
}

- (NSString *)windowNibName
{
	return @"Commit Editor";
}

- (void)saveWindowFrame
{
	[self.window saveFrameUsingName:ZGEditorWindowFrameNameKey];
}

- (void)windowDidLoad
{
	[self.window setFrameUsingName:ZGEditorWindowFrameNameKey];
	
	_style = [ZGWindowStyle windowStyleWithTheme:ZGReadDefaultWindowStyleTheme()];
	[self updateWindowStyle];
	
	NSData *data = [NSData dataWithContentsOfURL:_fileURL];
	if (data == nil)
	{
		fprintf(stderr, "Error: Couldn't load data from %s\n", _fileURL.path.UTF8String);
		exit(EXIT_FAILURE);
	}
	
	// If it's a git repo, set the label to the Project folder name, otherwise just use the filename
	NSURL *parentURL = _fileURL.URLByDeletingLastPathComponent;
	ZGVersionControlType versionControlType;
	NSString *label;
	
	if (_tutorialMode)
	{
		label = _fileURL.lastPathComponent;
		versionControlType = ZGVersionControlGit;
	}
	// We don't *have* to detect this for gits because we could look at the current working directory first,
	// but I want to rely on the current working directory as a last resort.
	else if ([parentURL.lastPathComponent isEqualToString:@".git"])
	{
		label = parentURL.URLByDeletingLastPathComponent.lastPathComponent;
		versionControlType = ZGVersionControlGit;
	}
	else
	{
		NSString *lastPathComponent = _fileURL.lastPathComponent;
		
		if ([lastPathComponent hasPrefix:@"hg-"])
		{
			versionControlType = ZGVersionControlHg;
		}
		else if ([lastPathComponent hasPrefix:@"svn-"])
		{
			versionControlType = ZGVersionControlSvn;
		}
		else
		{
			versionControlType = ZGVersionControlGit;
		}
		
		// git, hg, and svn seem to set current working directory to project directory before launching the editor
		label = [[[NSFileManager defaultManager] currentDirectoryPath] lastPathComponent];
	}
	
	_versionControlType = versionControlType;
	
	_commitLabelTextField.stringValue = (label == nil) ? @"" : label;
	
	// Give a little vertical padding between the text and the top of the text view container
	NSSize textContainerInset = _textView.textContainerInset;
	_textView.textContainerInset = NSMakeSize(textContainerInset.width, textContainerInset.height + 2);
	
	self.window.titlebarAppearsTransparent = YES;
	
	// Hide the window titlebar buttons
	// We still want the resize functionality to work even though the button is hidden
	[[self.window standardWindowButton:NSWindowCloseButton] setHidden:YES];
	[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
	[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
	
	// Nobody ever wants these;
	// Because macOS may have some of these settings globally in System Preferences, I don't trust IB very much..
	_textView.automaticDashSubstitutionEnabled = NO;
	_textView.automaticQuoteSubstitutionEnabled = NO;
	
	// Take care of other textview settings...
	[_textView zgLoadDefaults];
	
	_textView.textStorage.delegate = self;
	_textView.layoutManager.delegate = self;
	_textView.delegate = self;
	_textView.zgCommitViewDelegate = self;
	
	NSString *plainStringCandidate = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (plainStringCandidate == nil)
	{
		fprintf(stderr, "Error: Couldn't load plain-text from %s\n", _fileURL.path.UTF8String);
		exit(EXIT_FAILURE);
	}
	
	// It's unlikely we'll get content that has no line break, but if we do, just insert a newline character because Komet won't be able to deal with the content otherwise
	NSString *plainString;
	NSUInteger lineCount = [[plainStringCandidate componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
	if (lineCount <= 1)
	{
		plainString = @"\n";
	}
	else
	{
		plainString = plainStringCandidate;
	}
	
	_commentSectionLength = [self commentSectionLengthFromPlainText:plainString versionControlType:versionControlType];
	
	NSUInteger commitLength = [self commitTextLengthFromPlainText:plainString commentLength:_commentSectionLength];
	
	NSString *content = [plainString substringToIndex:commitLength];
	_initiallyContainedEmptyContent = ([[content stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] length] == 0);
	
	NSMutableAttributedString *plainAttributedString = [[NSMutableAttributedString alloc] initWithString:plainString attributes:@{}];
	
	if (_commentSectionLength != 0)
	{
		[plainAttributedString addAttribute:NSForegroundColorAttributeName value:_style.commentColor range:NSMakeRange(plainString.length - _commentSectionLength, _commentSectionLength)];
	}
	
	// I don't think we want to invoke beginEditing/endEditing, etc, events because we are setting the textview content for the first time,
	// and we don't want anything to register as user-editable yet or have undo activated yet
	[_textView.textStorage replaceCharactersInRange:NSMakeRange(0, 0) withAttributedString:plainAttributedString];
	
	[self updateEditorMessageFont];
	[self updateEditorCommentsFont];
	
	// Necessary to update text processing otherwise colors may not be right
	[self updateTextProcessing];
	
	[_textView setSelectedRange:NSMakeRange(commitLength, 0)];
	
	if (!_tutorialMode && (versionControlType == ZGVersionControlGit || versionControlType == ZGVersionControlHg))
	{
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		NSString *toolName = (versionControlType == ZGVersionControlGit) ? @"git" : @"hg";
		NSArray<NSString *> *toolArguments = (versionControlType == ZGVersionControlGit) ? @[@"rev-parse", @"--symbolic-full-name", @"--abbrev-ref", @"HEAD"] : @[@"branch"];
		
		NSString *pathToVersionControlSoftware = nil;
		for (NSString *parentDirectoryPath in [[[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"] componentsSeparatedByString:@":"])
		{
			NSString *pathToTool = [parentDirectoryPath stringByAppendingPathComponent:toolName];
			BOOL isDirectory;
			if ([fileManager fileExistsAtPath:pathToTool isDirectory:&isDirectory] && !isDirectory)
			{
				pathToVersionControlSoftware = pathToTool;
				break;
			}
		}
		
		if (pathToVersionControlSoftware != nil)
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSTask *branchTask = [[NSTask alloc] init];
				branchTask.launchPath = pathToVersionControlSoftware;
				
				if (versionControlType == ZGVersionControlGit)
				{
					branchTask.arguments = toolArguments;
				}
				else
				{
					branchTask.arguments = toolArguments;
				}
				
				NSPipe *standardOutputPipe = [NSPipe pipe];
				[branchTask setStandardOutput:standardOutputPipe];
				
				@try
				{
					[branchTask launch];
					[branchTask waitUntilExit];
					
					if (branchTask.terminationStatus == EXIT_SUCCESS)
					{
						NSData *dataRead = [standardOutputPipe.fileHandleForReading readDataToEndOfFile];
						NSString *branchName = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
						NSString *strippedBranchName = [branchName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						if (strippedBranchName != nil && strippedBranchName.length > 0)
						{
							dispatch_async(dispatch_get_main_queue(), ^{
								NSString *newLabel = [self->_commitLabelTextField.stringValue stringByAppendingFormat:@" (%@)", strippedBranchName];
								self->_commitLabelTextField.stringValue = newLabel;
							});
						}
					}
				}
				@catch (NSException *exception)
				{
					fprintf(stderr, "Error: Failed to fetch branch name: %s\n", exception.reason.UTF8String);
				}
			});
		}
	}
}

- (void)updateWindowStyle
{
	// Style top bar
	_topBar.wantsLayer = YES;
	_topBar.layer.backgroundColor = _style.barColor.CGColor;
	
	// Style top bar buttons
	_commitLabelTextField.textColor = _style.barTextColor;
	NSMutableAttributedString *commitTitle = [[NSMutableAttributedString alloc] initWithAttributedString:_commitButton.attributedTitle];
	[commitTitle addAttribute:NSForegroundColorAttributeName value:_style.barTextColor range:NSMakeRange(0, [_commitButton.title length])];
	[_commitButton setAttributedTitle:commitTitle];
	NSMutableAttributedString *cancelTitle = [[NSMutableAttributedString alloc] initWithAttributedString:_cancelButton.attributedTitle];
	[cancelTitle addAttribute:NSForegroundColorAttributeName value:_style.barTextColor range:NSMakeRange(0, [_cancelButton.title length])];
	[_cancelButton setAttributedTitle:cancelTitle];
	
	// Horizontal line bar divider
	_horizontalBarDivider.fillColor = _style.dividerLineColor;
	
	// Style text
	_textView.wantsLayer = YES;
	_textView.drawsBackground = NO;
	_textView.insertionPointColor = _style.textColor;
	
	NSColor *textHighlightColor = (_style.textHighlightColor == nil ? [NSColor selectedControlColor] : _style.textHighlightColor);
	[_textView setSelectedTextAttributes:@{NSBackgroundColorAttributeName: textHighlightColor, NSForegroundColorAttributeName: _style.barTextColor}];
	
	// Style content view
	BOOL vibrant = ZGReadDefaultWindowVibrancy();
	_contentView.state = (vibrant ? NSVisualEffectStateFollowsWindowActiveState : NSVisualEffectStateInactive);
	_contentView.material = _style.material;
	
	// Style scroll view
	_scrollView.scrollerKnobStyle = _style.scrollerKnobStyle;
	if (vibrant)
	{
		_scrollView.drawsBackground = NO;
	}
	else
	{
		_scrollView.drawsBackground = YES;
		_scrollView.backgroundColor = _style.fallbackBackgroundColor;
	}
}

- (void)updateFont:(NSFont *)newFont range:(NSRange)range
{
	[_textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
	
	// If we don't fix the font attributes, then attachments (like emoji) may become invisible and not show up
	[_textView.textStorage fixFontAttributeInRange:range];
}

- (void)updateEditorMessageFont
{
	[self updateFont:ZGReadDefaultMessageFont() range:NSMakeRange(0, _textView.textStorage.length - _commentSectionLength)];
}

- (void)updateEditorCommentsFont
{
	[self updateFont:ZGReadDefaultCommentsFont() range:NSMakeRange(_textView.textStorage.length - _commentSectionLength, _commentSectionLength)];
}

- (void)userDefaultsChangedMessageFont
{
	[self updateEditorMessageFont];
}

- (void)userDefaultsChangedCommentsFont
{
	[self updateEditorCommentsFont];
}

- (void)userDefaultsChangedRecommendedLineLengthLimits
{
	BOOL hasSubjectLimit = ZGReadDefaultRecommendedSubjectLengthLimitEnabled();
	BOOL hasBodyLineLimit = ZGReadDefaultRecommendedBodyLineLengthLimitEnabled();
	
	if (!hasSubjectLimit && !hasBodyLineLimit)
	{
		// Remove all background color highlighting in case any text is currently highlighted
		[self removeBackgroundColors];
	}
	else
	{
		[self updateTextProcessing];
	}
}

- (void)userDefaultsChangedEnableAutomaticSpellingCorrection
{
	[_textView setAutomaticSpellingCorrectionEnabled:ZGReadDefaultEnableAutomaticSpellingCorrection()];
}

- (IBAction)changeEditorTheme:(NSMenuItem *)sender
{
	ZGWindowStyleTheme newTheme = (ZGWindowStyleTheme)[sender tag];
	assert(newTheme <= ZGWindowStyleMaxTheme);
	
	ZGWindowStyleTheme currentTheme = ZGReadDefaultWindowStyleTheme();
	if (currentTheme != newTheme)
	{
		ZGWriteDefaultStyleTheme(newTheme);
		
		_style = [ZGWindowStyle windowStyleWithTheme:newTheme];
		[self updateWindowStyle];
		[self updateTextProcessing];
		[_topBar setNeedsDisplay:YES];
		[_contentView setNeedsDisplay:YES];
		
		// The comment section isn't updated by setting the editor style elsewhere, since it's not editable.
		[_textView.textStorage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange([_textView.textStorage.string length] - _commentSectionLength, _commentSectionLength)];
		[_textView.textStorage addAttribute:NSForegroundColorAttributeName value:_style.commentColor range:NSMakeRange([_textView.textStorage.string length] - _commentSectionLength, _commentSectionLength)];
	}
}

- (IBAction)changeVibrancy:(id)__unused sender
{
	ZGWriteDefaultWindowVibrancy(!ZGReadDefaultWindowVibrancy());
	[self updateWindowStyle];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(changeEditorTheme:))
	{
		ZGWindowStyleTheme currentTheme = ZGReadDefaultWindowStyleTheme();
		menuItem.state = (currentTheme == menuItem.tag) ? NSOnState : NSOffState;
	}
	else if (menuItem.action == @selector(changeVibrancy:))
	{
		menuItem.state = ZGReadDefaultWindowVibrancy() ? NSOnState : NSOffState;
	}
	return YES;
}

- (NSArray<NSValue *> *)contentLineRangesForTextStorage:(NSTextStorage *)textStorage
{
	NSString *plainText = textStorage.string;
	NSUInteger messageTextLength = plainText.length - _commentSectionLength;
	
	if (messageTextLength == 0)
	{
		return @[];
	}
	
	NSMutableArray<NSValue *> *lineRanges = [[NSMutableArray alloc] init];
	
	NSUInteger characterIndex = 0;
	while (characterIndex < messageTextLength)
	{
		NSUInteger lineStartIndex = 0;
		NSUInteger lineEndIndex = 0;
		NSUInteger contentEndIndex = 0;
		[plainText getLineStart:&lineStartIndex end:&lineEndIndex contentsEnd:&contentEndIndex forRange:NSMakeRange(characterIndex, 0)];
		
		NSRange lineRange = NSMakeRange(lineStartIndex, contentEndIndex - lineStartIndex);
		
		[lineRanges addObject:[NSValue valueWithRange:lineRange]];
		
		characterIndex = lineEndIndex;
	}
	
	return [lineRanges copy];
}

// -- Svn has a single comment line marker like this --
// but other VCSs like hg and git need a prefix for every line that is considered to be a comment
- (BOOL)hasSingleCommentLineMarkerForVersionControlType:(ZGVersionControlType)versionControlType
{
	switch (versionControlType)
	{
		case ZGVersionControlGit:
		case ZGVersionControlHg:
			return NO;
		case ZGVersionControlSvn:
			return YES;
	}
}

- (void)updateCommentAttributesWithContentLineRanges:(NSArray<NSValue *> *)contentLineRanges
{
	// If there's only one comment line marker, we need not worry about attributing comments
	if ([self hasSingleCommentLineMarkerForVersionControlType:_versionControlType])
	{
		return;
	}
	
	NSTextStorage *textStorage = _textView.textStorage;
	NSString *plainText = textStorage.string;
	NSFont *commentFont = nil;
	
	// First assume all content has no comment lines
	[self updateFont:ZGReadDefaultMessageFont() range:NSMakeRange(0, plainText.length - _commentSectionLength)];
	
	for (NSValue *contentLineRangeValue in contentLineRanges)
	{
		NSRange contentLineRange = contentLineRangeValue.rangeValue;
		if (contentLineRange.length > 0 && [self isCommentLine:[plainText substringWithRange:contentLineRange] forVersionControlType:_versionControlType])
		{
			// Add comment font attribute for lines that are comments
			[textStorage addAttribute:NSForegroundColorAttributeName value:_style.commentColor range:contentLineRange];
			
			if (commentFont == nil)
			{
				commentFont = ZGReadDefaultCommentsFont();
			}
			[self updateFont:commentFont range:contentLineRange];
		}
		else
		{
			[textStorage removeAttribute:NSForegroundColorAttributeName range:contentLineRange];
		}
	}
}

- (void)removeBackgroundColors
{
	[_textView.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, _textView.textStorage.length)];
}

- (void)updateHighlightingWithContentLineRanges:(NSArray<NSValue *> *)contentLineRanges forLineLimitsAllowingSubjectLimit:(BOOL)allowingSubjectLimit subjectLengthLimit:(NSUInteger)subjectLengthLimit allowingingBodyLimit:(BOOL)allowingBodyLimit bodyLengthLimit:(NSUInteger)bodyLengthLimit
{
	if (!allowingSubjectLimit && !allowingBodyLimit)
	{
		return;
	}
	
	if (contentLineRanges.count == 0)
	{
		return;
	}
	
	// Remove the attribute everywhere. Might be "inefficient" but it's the easiest most reliable approach I know how to do
	[self removeBackgroundColors];
	
	for (NSValue *contentLineRangeValue in contentLineRanges)
	{
		NSRange lineRange = contentLineRangeValue.rangeValue;
		if (lineRange.location == 0)
		{
			if (allowingSubjectLimit)
			{
				[self highlightOverflowingTextWithLineRange:lineRange limit:subjectLengthLimit];
			}
			
			if (!allowingBodyLimit)
			{
				break;
			}
		}
		else
		{
			[self highlightOverflowingTextWithLineRange:lineRange limit:bodyLengthLimit];
		}
	}
}

- (void)updateContentStyleWithContentLineRanges:(NSArray<NSValue *> *)contentLineRanges
{
	if (contentLineRanges.count == 0)
	{
		return;
	}
	
	NSTextStorage *textStorage = _textView.textStorage;
	NSString *plainText = textStorage.string;
	
	for (NSValue *contentLineRangeValue in contentLineRanges)
	{
		NSRange lineRange = contentLineRangeValue.rangeValue;
		if (lineRange.length > 0 && ![self isCommentLine:[plainText substringWithRange:lineRange] forVersionControlType:_versionControlType])
		{
			[textStorage removeAttribute:NSForegroundColorAttributeName range:lineRange];
			[textStorage addAttribute:NSForegroundColorAttributeName value:_style.textColor range:lineRange];
		}
	}
}

- (void)highlightOverflowingTextWithLineRange:(NSRange)lineRange limit:(NSUInteger)limit
{
	if (lineRange.length > limit)
	{
		NSRange overflowRange = NSMakeRange(lineRange.location + limit, lineRange.length - limit);
		[_textView.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:_style.overflowColor forCharacterRange:overflowRange];
	}
}

// Don't allow editing the comment section
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray<NSValue *> *)affectedRanges replacementStrings:(NSArray<NSString *> *)__unused replacementStrings
{
	NSUInteger plainTextLength = textView.textStorage.string.length;
	for (NSValue *rangeValue in affectedRanges)
	{
		NSRange range = rangeValue.rangeValue;
		if (range.location + range.length >= plainTextLength - _commentSectionLength)
		{
			return NO;
		}
	}
	return YES;
}

- (void)updateTextProcessing
{
	NSArray<NSValue *> *contentLineRanges = [self contentLineRangesForTextStorage:_textView.textStorage];
	
	[self
	 updateHighlightingWithContentLineRanges:contentLineRanges
	 forLineLimitsAllowingSubjectLimit:ZGReadDefaultRecommendedSubjectLengthLimitEnabled()
	 subjectLengthLimit:ZGReadDefaultRecommendedSubjectLengthLimit()
	 allowingingBodyLimit:ZGReadDefaultRecommendedBodyLineLengthLimitEnabled()
	 bodyLengthLimit:ZGReadDefaultRecommendedBodyLineLengthLimit()];
	
	[self updateCommentAttributesWithContentLineRanges:contentLineRanges];
	
	[self updateContentStyleWithContentLineRanges:contentLineRanges];
}

- (void)textDidChange:(NSNotification *)__unused notification
{
	[self updateTextProcessing];
}

- (NSDictionary<NSString *,id> *)layoutManager:(NSLayoutManager *)__unused layoutManager shouldUseTemporaryAttributes:(NSDictionary<NSString *, id> *)attrs forDrawingToScreen:(BOOL)toScreen atCharacterIndex:(NSUInteger)characterIndex effectiveRange:(NSRangePointer)__unused effectiveCharRange
{
	NSDictionary<NSString *,id> * attributes;
	if (!toScreen)
	{
		attributes = nil;
	}
	else
	{
		NSString *plainText = _textView.textStorage.string;
		
		NSUInteger lineStartIndex = 0;
		NSUInteger contentEndIndex = 0;
		[plainText getLineStart:&lineStartIndex end:NULL contentsEnd:&contentEndIndex forRange:NSMakeRange(characterIndex, 0)];
		
		// Disable temporary attributes like spell checking if they are in a comment line
		if ([self isCommentLine:[plainText substringWithRange:NSMakeRange(lineStartIndex, contentEndIndex - lineStartIndex)] forVersionControlType:_versionControlType])
		{
			attributes = nil;
		}
		else
		{
			attributes = attrs;
		}
	}
	return attributes;
}

- (NSInteger)textView:(NSTextView *)textView shouldSetSpellingState:(NSInteger)value range:(NSRange)affectedCharRange
{
	NSString *plainText = textView.textStorage.string;
	
	NSUInteger lineStartIndex = 0;
	NSUInteger contentEndIndex = 0;
	[plainText getLineStart:&lineStartIndex end:NULL contentsEnd:&contentEndIndex forRange:affectedCharRange];
	
	// Don't check for anything spelling related if the range is in a comment line
	NSInteger newValue;
	if ([self isCommentLine:[plainText substringWithRange:NSMakeRange(lineStartIndex, contentEndIndex - lineStartIndex)] forVersionControlType:_versionControlType])
	{
		newValue = 0;
	}
	else
	{
		newValue = value;
	}
	
	return newValue;
}

- (BOOL)textView:(NSTextView *)__unused textView doCommandBySelector:(SEL)selector
{
	if (selector == @selector(insertNewline:))
	{
		// After the user enters a new line in the first line, we want to insert another newline due to commit'ing conventions
		// for leaving a blank line right after the subject (first) line
		// We will also have some prevention if the user performs a new line more than once consecutively
		BOOL insertsAutomaticNewline = ZGReadDefaultAutomaticNewlineInsertionAfterSubjectLine();
		if (insertsAutomaticNewline)
		{
			if (_preventAccidentalNewline)
			{
				return YES;
			}
			else
			{
				NSArray<NSValue *> *selectedRanges = _textView.selectedRanges;
				if (selectedRanges.count == 1)
				{
					NSRange range = [selectedRanges[0] rangeValue];
					
					NSUInteger lineStartIndex = 0;
					NSUInteger lineEndIndex = 0;
					NSUInteger contentEndIndex = 0;
					
					NSString *plainText = _textView.textStorage.string;
					[plainText getLineStart:&lineStartIndex end:&lineEndIndex contentsEnd:&contentEndIndex forRange:range];
					
					if (lineStartIndex == 0 && (contentEndIndex - lineStartIndex > 0) && (lineEndIndex == plainText.length - _commentSectionLength || isspace([plainText characterAtIndex:lineEndIndex])))
					{
						// We need to invoke these methods to get proper undo support
						// http://lists.apple.com/archives/cocoa-dev/2004/Jan/msg01925.html
						NSString *replacement = @"\n\n";
						if ([_textView shouldChangeTextInRange:range replacementString:replacement])
						{
							[_textView.textStorage beginEditing];
							
							[_textView.textStorage replaceCharactersInRange:range withString:replacement];
							
							[_textView.textStorage endEditing];
							[_textView didChangeText];
							
							_preventAccidentalNewline = YES;
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
								self->_preventAccidentalNewline = NO;
							});
							return YES;
						}
					}
				}
			}
		}
	}
	return NO;
}

- (void)exitWithSuccess:(BOOL)success __attribute__((noreturn))
{
	[self saveWindowFrame];
	
	if (_tutorialMode)
	{
		NSURL *parentURL = _fileURL.URLByDeletingLastPathComponent;
		if (parentURL != nil)
		{
			[[NSFileManager defaultManager] removeItemAtURL:parentURL error:NULL];
		}
	}
	
	if (success)
	{
		// We should have wrote to the commit file successfully
		exit(EXIT_SUCCESS);
	}
	else
	{
		if (_initiallyContainedEmptyContent)
		{
			// Empty commits should be treated as a success
			// Version control software will be able to handle it as an abort
			exit(EXIT_SUCCESS);
		}
		else
		{
			// If we are amending an existing commit for example, we should fail and not create another change
			exit(EXIT_FAILURE);
		}
	}
}

- (IBAction)commit:(id)__unused sender
{
	NSError *writeError = nil;
	if (![_textView.textStorage.string writeToURL:_fileURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError])
	{
		// Fatal error
		fprintf(stderr, "Failed to write to %s because of: %s\n", _fileURL.path.UTF8String, writeError.localizedDescription.UTF8String);
		exit(EXIT_FAILURE);
	}
	
	[self exitWithSuccess:YES];
}

// Do not name this method as "cancel:" because it will automatically respond to esc being invoked
- (IBAction)cancelCommit:(id)__unused sender
{
	[self exitWithSuccess:NO];
}

// Invoked from our custom ZGCommitTextView delegate

- (void)zgCommitViewSelectAll
{
	NSString *plainText = _textView.textStorage.string;
	NSUInteger commitTextLength = [self commitTextLengthFromPlainText:plainText commentLength:_commentSectionLength];
	[_textView setSelectedRange:NSMakeRange(0, commitTextLength)];
}

- (void)zgCommitViewTouchCommit:(id)__unused sender
{
	[self commit:nil];
}

- (void)zgCommitViewTouchCancel:(id)__unused sender
{
	[self cancelCommit:nil];
}

- (BOOL)isCommentLine:(NSString *)line forVersionControlType:(ZGVersionControlType)versionControlType
{
	NSString *prefixCommentString;
	NSString *suffixCommentString;
	switch (versionControlType)
	{
		case ZGVersionControlGit:
			prefixCommentString = @"#";
			suffixCommentString = @"";
			break;
		case ZGVersionControlHg:
			prefixCommentString = @"HG:";
			suffixCommentString = @"";
			break;
		case ZGVersionControlSvn:
			prefixCommentString = @"--";
			suffixCommentString = @"--";
			break;
	}
	
	// Note a line that is "--" could have the prefix and suffix the same, but we want to make sure it's at least "--...--" length long
	// Also empty strings don't yield the expected behavior for hasSuffix:/hasPrefix: (i.e, Foundation thinks "" is not a prefix or suffix of "foo")
	return ([line hasPrefix:prefixCommentString] && (line.length >= prefixCommentString.length + suffixCommentString.length) && (suffixCommentString.length == 0 || [line hasSuffix:suffixCommentString]));
}

// The comment range should begin at the line that starts with a comment string and extend to the end of the file.
// Additionally, there should be no content lines (i.e, non comment lines) within this section
// (exception: unless we're dealing with svn which only has a starting point for comments)
// This should only be computed once, before the user gets a chance to edit the content
- (NSUInteger)commentSectionLengthFromPlainText:(NSString *)plainText versionControlType:(ZGVersionControlType)versionControlType
{
	NSUInteger plainTextLength = plainText.length;
	
	NSUInteger characterIndex = 0;
	NSUInteger commentSectionCharacterIndex = 0;
	BOOL foundCommentSection = NO;
	while (characterIndex < plainTextLength)
	{
		NSUInteger lineStartIndex = 0;
		NSUInteger lineEndIndex = 0;
		NSUInteger contentEndIndex = 0;
		[plainText getLineStart:&lineStartIndex end:&lineEndIndex contentsEnd:&contentEndIndex forRange:NSMakeRange(characterIndex, 0)];
		
		NSString *line = [plainText substringWithRange:NSMakeRange(lineStartIndex, contentEndIndex - lineStartIndex)];
		
		BOOL commentLine = [self isCommentLine:line forVersionControlType:versionControlType];
		if (!commentLine && foundCommentSection && [[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0)
		{
			// If we found a content line that is not empty, then we have to find a better starting point for the comment section
			foundCommentSection = NO;
		}
		else if (commentLine && !foundCommentSection)
		{
			foundCommentSection = YES;
			commentSectionCharacterIndex = characterIndex;
			
			// If there's only a single comment line marker, then we're done
			if ([self hasSingleCommentLineMarkerForVersionControlType:versionControlType])
			{
				break;
			}
		}
		
		characterIndex = lineEndIndex;
	}
	
	NSUInteger commentSectionLength = foundCommentSection ? (plainTextLength - commentSectionCharacterIndex) : 0;
	return commentSectionLength;
}

// The content range should extend to before the comments, only allowing one trailing newline in between the comments and content
// Make sure to scan from the bottom to top
- (NSUInteger)commitTextLengthFromPlainText:(NSString *)plainText commentLength:(NSUInteger)commentLength
{
	// Find the first real character or anything past the 1st newline before the comment section
	NSUInteger bestEndCharacterIndex = plainText.length - commentLength;
	BOOL passedNewline = NO;
	while (bestEndCharacterIndex > 0)
	{
		bestEndCharacterIndex--;
		
		unichar character = [plainText characterAtIndex:bestEndCharacterIndex];
		if (character == '\n')
		{
			if (passedNewline)
			{
				break;
			}
			passedNewline = YES;
		}
		else
		{
			bestEndCharacterIndex++;
			break;
		}
	}
	
	return bestEndCharacterIndex;
}

@end
