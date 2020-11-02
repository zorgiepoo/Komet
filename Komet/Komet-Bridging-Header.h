//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "ZGUpdaterController.h"
#import "ZGUpdaterSettingsListener.h"

#import <Cocoa/Cocoa.h>

@interface NSTextView (OverridableSetters)

- (void)setContinuousSpellCheckingEnabled:(BOOL)continuousSpellCheckingEnabled;
- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)automaticSpellingCorrectionEnabled;
- (void)setAutomaticTextReplacementEnabled:(BOOL)automaticTextReplacementEnabled;

@end
