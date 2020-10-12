//
//  ZGBreadcrumbs.m
//  Komet
//
//  Created by Mayur Pawashe on 10/10/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

#import "ZGBreadcrumbs.h"

#define BREADCRUMB_EXIT_STATUS @"exit_status"
#define BREADCRUMB_TEXT_OVERFLOW_RANGES @"text_overflow_ranges"
#define BREADCRUMB_COMMENT_LINE_RANGES @"comment_line_ranges"
#define BREADCRUMB_SPELL_CHECKING @"spell_checking"

#define BREADCRUMB_RANGE_LOCATION @"location"
#define BREADCRUMB_RANGE_LENGTH @"length"

@implementation ZGBreadcrumbs
{
	NSURL *_fileURL;
}

- (instancetype)init
{
	self = [super init];
	if (self != nil)
	{
		_textOverflowRanges = [[NSMutableArray alloc] init];
		_commentLineRanges = [[NSMutableArray alloc] init];
	}
	return self;
}

+ (instancetype)breadcrumbsWritingToURL:(NSURL *)fileURL
{
	ZGBreadcrumbs *breadcrumbs = [[ZGBreadcrumbs alloc] init];
	if (breadcrumbs != nil)
	{
		breadcrumbs->_fileURL = fileURL;
	}
	return breadcrumbs;
}

static BOOL _decodeRanges(NSDictionary *jsonDictionary, NSString *rangesKey, NSMutableArray<NSValue *> *breadcrumbRanges)
{
	NSArray *ranges = jsonDictionary[rangesKey];
	if (ranges == nil || ![ranges isKindOfClass:[NSArray class]])
	{
		return NO;
	}
	
	for (id<NSObject> rangeObject in ranges)
	{
		if (![rangeObject isKindOfClass:[NSDictionary class]])
		{
			return NO;
		}
		
		NSNumber *locationObject = ((NSDictionary *)rangeObject)[BREADCRUMB_RANGE_LOCATION];
		if (locationObject == nil || ![locationObject isKindOfClass:[NSNumber class]])
		{
			return NO;
		}
		
		NSNumber *lengthObject = ((NSDictionary *)rangeObject)[BREADCRUMB_RANGE_LENGTH];
		if (lengthObject == nil || ![lengthObject isKindOfClass:[NSNumber class]])
		{
			return NO;
		}
		
		[breadcrumbRanges addObject:[NSValue valueWithRange:NSMakeRange(locationObject.unsignedIntegerValue, lengthObject.unsignedIntegerValue)]];
	}
	
	return YES;
}

+ (instancetype _Nullable)breadcrumbsReadingFromURL:(NSURL *)fileURL
{
	ZGBreadcrumbs *breadcrumbs = [[ZGBreadcrumbs alloc] init];
	if (breadcrumbs == nil)
	{
		return nil;
	}
	
	breadcrumbs->_fileURL = fileURL;
	
	NSError *dataError = nil;
	NSData *data = [NSData dataWithContentsOfURL:fileURL options:0 error:&dataError];
	if (data == nil)
	{
		NSLog(@"Failed to read breadcrumbs file: %@", dataError);
		return nil;
	}
	
	NSError *serializationError = nil;
	id<NSObject> jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
	if (jsonObject == nil)
	{
		NSLog(@"Failed to read json data from breadcrumbs: %@", serializationError);
		return nil;
	}
	
	if (![jsonObject isKindOfClass:[NSDictionary class]])
	{
		NSLog(@"json object is not a dictionary!");
		return nil;
	}
	
	NSDictionary *jsonDictionary = (NSDictionary *)jsonObject;
	
	NSNumber *exitStatusObject = jsonDictionary[BREADCRUMB_EXIT_STATUS];
	if (exitStatusObject == nil || ![exitStatusObject isKindOfClass:[NSNumber class]])
	{
		NSLog(@"Exit status is not valid from breadcrumbs");
		return nil;
	}
	
	breadcrumbs->_exitStatus = exitStatusObject.intValue;
	
	NSNumber *spellCheckingObject = jsonDictionary[BREADCRUMB_SPELL_CHECKING];
	if (spellCheckingObject == nil || ![spellCheckingObject isKindOfClass:[NSNumber class]])
	{
		NSLog(@"spell checking is not valid from breadcrumbs");
		return nil;
	}
	
	breadcrumbs->_spellChecking = spellCheckingObject.boolValue;
	
	if (!_decodeRanges(jsonDictionary, BREADCRUMB_TEXT_OVERFLOW_RANGES, breadcrumbs->_textOverflowRanges))
	{
		NSLog(@"Failed to decode breadcrumb text overflow ranges");
		return nil;
	}
	
	if (!_decodeRanges(jsonDictionary, BREADCRUMB_COMMENT_LINE_RANGES, breadcrumbs->_commentLineRanges))
	{
		NSLog(@"Failed to decode breadcrumb comment line ranges");
		return nil;
	}
	
	return breadcrumbs;
}

static NSDictionary<NSString *, NSNumber *> *rangeToDictionary(NSRange range)
{
	return @{BREADCRUMB_RANGE_LOCATION : @(range.location), BREADCRUMB_RANGE_LENGTH : @(range.length)};
}

static NSArray<NSDictionary<NSString *, NSNumber *> *> *rangesToJSONArray(NSArray<NSValue *> *ranges)
{
	NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *jsonObjects = [[NSMutableArray alloc] init];
	
	for (NSValue *rangeValue in ranges)
	{
		[jsonObjects addObject:rangeToDictionary(rangeValue.rangeValue)];
	}
	
	return [jsonObjects copy];
}

- (void)saveFile
{
	NSDictionary *contents = @{BREADCRUMB_EXIT_STATUS : @(_exitStatus), BREADCRUMB_TEXT_OVERFLOW_RANGES : rangesToJSONArray(_textOverflowRanges), BREADCRUMB_COMMENT_LINE_RANGES : rangesToJSONArray(_commentLineRanges), BREADCRUMB_SPELL_CHECKING : @(_spellChecking)};
	
	[[NSFileManager defaultManager] removeItemAtURL:_fileURL error:NULL];
	
	NSError *serializeError = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:contents options:NSJSONWritingPrettyPrinted error:&serializeError];
	if (data == nil)
	{
		NSLog(@"Failed to write breadcrumb data: %@", serializeError);
		abort();
	}
	
	NSError *writeError = nil;
	if (![data writeToURL:_fileURL options:NSDataWritingAtomic error:&writeError])
	{
		NSLog(@"Failed to write breadcrumbs file: %@", writeError);
		abort();
	}
}

@end
