//
//  ZGEditorWindowController.m
//  Komet
//
//  Created by Mayur Pawashe on 8/16/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

#import "ZGEditorWindowController.h"
#import "ZGCommitTextView.h"

#define ZGEditorWindowFrameNameKey @"ZGEditorWindowFrame"
#define ZGEditorFontNameKey @"ZGEditorFontName"
#define ZGEditorFontSizeKey @"ZGEditorFontSize"
#define ZGEditorRecommendedSubjectLengthLimitKey @"ZGEditorRecommendedSubjectLengthLimit"
#define ZGEditorSubjectOverflowBackgroundColorKey @"ZGEditorSubjectOverflowBackgroundColor"
#define ZGEditorCommentForegroundColorKey @"ZGEditorCommentForegroundColor"
#define ZGEditorAutomaticNewlineInsertionAfterSubjectKey @"ZGEditorAutomaticNewlineInsertionAfterSubject"

@interface ZGEditorWindowController () <NSTextStorageDelegate, NSLayoutManagerDelegate, NSTextViewDelegate>
@end

@implementation ZGEditorWindowController
{
	NSURL *_fileURL;
	IBOutlet ZGCommitTextView *_textView;
	IBOutlet NSTextField *_commitLabelTextField;
	BOOL _preventAccidentalNewline;
}

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		const CGFloat fontSize = 11.0;
		
		// This is the max subject length GitHub uses before the subject overflows
		// Not using 50 because I think it may be too irritating of a default for Mac users
		const NSUInteger maxRecommendedSubjectLengthLimit = 69;
		
		NSColor *commentColor = [[NSColor darkGrayColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		
		[defaults registerDefaults:@{ZGEditorFontNameKey : @"", ZGEditorFontSizeKey : @(fontSize), ZGEditorRecommendedSubjectLengthLimitKey : @(maxRecommendedSubjectLengthLimit), ZGEditorSubjectOverflowBackgroundColorKey : @"1.0,0.0,0.0,0.3", ZGEditorCommentForegroundColorKey : [NSString stringWithFormat:@"%f,%f,%f,%f", commentColor.redComponent, commentColor.greenComponent, commentColor.blueComponent, commentColor.alphaComponent], ZGEditorAutomaticNewlineInsertionAfterSubjectKey : @YES}];
	});
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
	self = [super init];
	if (self != nil)
	{
		_fileURL = fileURL;
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

- (NSFont *)defaultFontOfSize:(CGFloat)size
{
	NSFont *defaultFont;
	// 10.12 may have SF Mono system wide
	NSFont *sfMonoFont = [NSFont fontWithName:@"SF Mono" size:size];
	// Revert to older font face on older systems
	if (sfMonoFont != nil)
	{
		defaultFont = sfMonoFont;
	}
	else
	{
		// Default font Xcode 7 uses
		NSFont *menloFont = [NSFont fontWithName:@"Menlo" size:size];
		if (menloFont != nil)
		{
			defaultFont = menloFont;
		}
		else
		{
			// If we get here, we are especially desperate
			defaultFont = [NSFont systemFontOfSize:size];
		}
	}
	return defaultFont;
}

- (void)windowDidLoad
{
	[self.window setFrameUsingName:ZGEditorWindowFrameNameKey];
	
	NSData *data = [NSData dataWithContentsOfURL:_fileURL];
	if (data == nil)
	{
		printf("Error: Couldn't load data from %s\n", _fileURL.path.UTF8String);
		exit(EXIT_FAILURE);
	}
	
	// If it's a git repo, set the label to the Project folder name, otherwise just use the filename
	NSURL *parentURL = _fileURL.URLByDeletingLastPathComponent;
	NSString *label;
	if ([parentURL.lastPathComponent isEqualToString:@".git"])
	{
		label = parentURL.URLByDeletingLastPathComponent.lastPathComponent;
	}
	else
	{
		label = _fileURL.lastPathComponent;
	}
	
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
	
	NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:ZGEditorFontNameKey];
	CGFloat fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey:ZGEditorFontNameKey];
	
	NSFont *font;
	if (fontName.length == 0)
	{
		font = [self defaultFontOfSize:fontSize];
	}
	else
	{
		NSFont *userFont = [NSFont fontWithName:fontName size:fontSize];
		if (userFont != nil)
		{
			font = userFont;
		}
		else
		{
			font = [self defaultFontOfSize:fontSize];
		}
	}
	
	NSString *plainString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (plainString == nil)
	{
		printf("Error: Couldn't load plain-text from %s\n", _fileURL.path.UTF8String);
		exit(EXIT_FAILURE);
	}
	
	NSAttributedString *plainAttributedString = [[NSAttributedString alloc] initWithString:plainString attributes:@{NSFontAttributeName : font}];
	
	[_textView.textStorage setAttributedString:plainAttributedString];
	
	NSRange commentRange = {.location = 0, .length = 0};
	NSUInteger commitLength = [self commitTextLengthAndGetCommentRange:&commentRange];
	
	[_textView setSelectedRange:NSMakeRange(commitLength, 0)];
	if (commentRange.length != 0)
	{
		[_textView.textStorage addAttribute:NSForegroundColorAttributeName value:[self colorFromUserDefaultsKey:ZGEditorCommentForegroundColorKey] range:commentRange];
	}
}

- (NSColor *)colorFromUserDefaultsKey:(NSString *)userDefaultsKey
{
	NSColor *color = nil;
	NSString *colorString = [[NSUserDefaults standardUserDefaults] stringForKey:userDefaultsKey];
	if (colorString != nil)
	{
		NSArray<NSString *> *colorComponents = [colorString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];
		
		if (colorComponents.count == 3)
		{
			color = [NSColor colorWithRed:colorComponents[0].doubleValue green:colorComponents[1].doubleValue blue:colorComponents[2].doubleValue alpha:1.0];
		}
		else if (colorComponents.count == 4)
		{
			color = [NSColor colorWithRed:colorComponents[0].doubleValue green:colorComponents[1].doubleValue blue:colorComponents[2].doubleValue alpha:colorComponents[3].doubleValue];
		}
	}
	
	if (color == nil)
	{
		color = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	}
	return color;
}

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)__unused editedRange changeInLength:(NSInteger)__unused delta
{
	if ((editedMask & NSTextStorageEditedCharacters) != 0)
	{
		NSUInteger maxRecommendedSubjectLength = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:ZGEditorRecommendedSubjectLengthLimitKey];
		
		if (maxRecommendedSubjectLength > 0)
		{
			// I am trying to highlight text on the first line if it exceeds certain number of characters (similar to a Twitter mesage overflowing).
			NSString *plainText = textStorage.string;
			if (plainText.length > 0)
			{
				// Remove the attribute everywhere. Might be "inefficient" but it's the easiest most reliable approach I know how to do
				[_textView.textStorage removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, plainText.length)];
				
				// Then get the content line range
				NSUInteger startLineIndex = 0;
				NSUInteger contentEndIndex = 0;
				
				[plainText getLineStart:&startLineIndex end:NULL contentsEnd:&contentEndIndex forRange:NSMakeRange(0, 1)];
				
				NSRange lineContentRange = NSMakeRange(startLineIndex, contentEndIndex - startLineIndex);
				
				// Then get the overflow range
				if (lineContentRange.length > maxRecommendedSubjectLength)
				{
					NSRange overflowRange = NSMakeRange(maxRecommendedSubjectLength, lineContentRange.length - maxRecommendedSubjectLength);
					
					// Highlight the overflow background
					NSColor *overflowColor = [self colorFromUserDefaultsKey:ZGEditorSubjectOverflowBackgroundColorKey];
					[_textView.textStorage addAttribute:NSBackgroundColorAttributeName value:overflowColor range:overflowRange];
				}
			}
		}
	}
}

- (NSDictionary<NSString *,id> *)layoutManager:(NSLayoutManager *)__unused layoutManager shouldUseTemporaryAttributes:(NSDictionary<NSString *, id> *)attrs forDrawingToScreen:(BOOL)toScreen atCharacterIndex:(NSUInteger)__unused charIndex effectiveRange:(NSRangePointer)effectiveCharRange
{
	NSDictionary<NSString *,id> * attributes;
	if (!toScreen)
	{
		attributes = nil;
	}
	else
	{
		// Disable temporary attributes like spell checking red squiggle underlines if the line begins with a #
		NSUInteger lineStartIndex = 0;
		NSString *plainText = _textView.textStorage.string;
		[plainText getLineStart:&lineStartIndex end:NULL contentsEnd:NULL forRange:*effectiveCharRange];
		if ([plainText characterAtIndex:lineStartIndex] == '#')
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

- (BOOL)textView:(NSTextView *)__unused textView doCommandBySelector:(SEL)selector
{
	if (selector == @selector(insertNewline:))
	{
		// After the user enters a new line in the first line, we want to insert another newline due to commit'ing conventions
		// for leaving a blank line right after the subject (first) line
		// We will also have some prevention if the user performs a new line more than once consecutively
		BOOL insertsAutomaticNewline = [[NSUserDefaults standardUserDefaults] boolForKey:ZGEditorAutomaticNewlineInsertionAfterSubjectKey];
		
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
					NSString *plainText = _textView.textStorage.string;
					[plainText getLineStart:&lineStartIndex end:NULL contentsEnd:NULL forRange:range];
					
					if (lineStartIndex == 0)
					{
						// By telling NSTextView we are begin/end editing and changed text,
						// the text view will have better undo behavior
						[_textView insertNewline:nil];
						[_textView insertNewline:nil];
						
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
	return NO;
}

- (void)exitWithStatus:(int)status __attribute__((noreturn))
{
	[self saveWindowFrame];
	exit(status);
}

- (void)windowWillClose:(NSNotification *)__unused notification
{
	[self exitWithStatus:EXIT_FAILURE];
}

- (IBAction)commit:(id)__unused sender
{
	NSError *writeError = nil;
	if (![_textView.textStorage.string writeToURL:_fileURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError])
	{
		printf("Failed to write to %s because of: %s\n", _fileURL.path.UTF8String, writeError.localizedDescription.UTF8String);
		exit(EXIT_FAILURE);
	}
	
	[self exitWithStatus:EXIT_SUCCESS];
}

- (IBAction)cancel:(id)__unused sender
{
	[self exitWithStatus:EXIT_FAILURE];
}

- (IBAction)selectAllCommitText:(id)__unused sender
{
	[_textView setSelectedRange:NSMakeRange(0, [self commitTextLength])];
}

- (NSUInteger)commitTextLength
{
	return [self commitTextLengthAndGetCommentRange:NULL];
}

// The content range should extend to before the comments, only allowing one trailing newline in between the comments and content
// The comment range should begin at the first line that starts with '#' and end to end of the file
// Make sure to scan from the bottom to top
- (NSUInteger)commitTextLengthAndGetCommentRange:(NSRange *)commentRange
{
	NSString *plainText = _textView.textStorage.string;
	NSUInteger plainTextLength = plainText.length;
	
	NSUInteger firstCommentLineIndex = 0;
	
	BOOL foundFirstCommentLine = NO;
	
	// Find the first comment line starting from the end of the document to get the comment range to the end of the document
	NSUInteger characterIndex = plainTextLength;
	while (characterIndex > 0)
	{
		characterIndex--;
		
		NSUInteger lineStartIndex = 0;
		[plainText getLineStart:&lineStartIndex end:NULL contentsEnd:NULL forRange:NSMakeRange(characterIndex, 0)];
		
		unichar character = [plainText characterAtIndex:lineStartIndex];
		if (character != '#')
		{
			if (foundFirstCommentLine)
			{
				if (commentRange != NULL)
				{
					*commentRange = NSMakeRange(firstCommentLineIndex, plainTextLength - firstCommentLineIndex);
				}
				
				break;
			}
		}
		else
		{
			foundFirstCommentLine = YES;
			firstCommentLineIndex = lineStartIndex;
		}
		
		characterIndex = lineStartIndex;
	}
	
	// Find the first real character or anything past the 1st newline before the comment section
	NSUInteger bestEndCharacterIndex = firstCommentLineIndex;
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
