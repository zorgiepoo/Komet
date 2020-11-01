//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "ZGUpdaterController.h"
#import "ZGUserDefaultsEditorListener.h"
#import "ZGWindowStyleTheme.h"
#import "ZGWindowStyle.h"
#import "ZGUserDefaultsEditorListener.h"
#import "ZGUpdaterSettingsListener.h"

@interface NSTextView (OverridableSetters)

- (void)setContinuousSpellCheckingEnabled:(BOOL)continuousSpellCheckingEnabled;
- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)automaticSpellingCorrectionEnabled;
- (void)setAutomaticTextReplacementEnabled:(BOOL)automaticTextReplacementEnabled;

@end
