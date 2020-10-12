//
//  ZGBreadcrumbs.h
//  Komet
//
//  Created by Mayur Pawashe on 10/10/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface ZGBreadcrumbs : NSObject

+ (instancetype)breadcrumbsWritingToURL:(NSURL *)fileURL;
+ (instancetype _Nullable)breadcrumbsReadingFromURL:(NSURL *)fileURL;

@property (nonatomic) int exitStatus;
@property (nonatomic, readonly) NSMutableArray<NSValue *> *textOverflowRanges;
@property (nonatomic, readonly) NSMutableArray<NSValue *> *commentLineRanges;
@property (nonatomic) BOOL spellChecking;

- (void)saveFile;

@end

NS_ASSUME_NONNULL_END
