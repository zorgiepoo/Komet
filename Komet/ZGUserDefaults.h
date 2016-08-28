//
//  ZGUserDefaults.h
//  Komet
//
//  Created by Mayur Pawashe on 8/28/16.
//  Copyright © 2016 zgcoder. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

void ZGRegisterDefaultMessageFont(void);
NSFont *ZGReadDefaultMessageFont(void);
void ZGWriteDefaultMessageFont(NSFont *font);

void ZGRegisterDefaultCommentsFont(void);
NSFont *ZGReadDefaultCommentsFont(void);
void ZGWriteDefaultCommentsFont(NSFont *font);

void ZGRegisterDefaultRecommendedSubjectLengthLimit(void);
NSUInteger ZGReadDefaultRecommendedSubjectLengthLimit(void);
void ZGWriteDefaultRecommendedSubjectLengthLimit(NSUInteger recommendedSubjectLengthLimit);

void ZGRegisterDefaultRecommendedSubjectLengthLimitEnabled(void);
BOOL ZGReadDefaultRecommendedSubjectLengthLimitEnabled(void);
void ZGWriteDefaultRecommendedSubjectLengthLimitEnabled(BOOL enabled);

void ZGRegisterDefaultRecommendedBodyLineLengthLimit(void);
NSUInteger ZGReadDefaultRecommendedBodyLineLengthLimit(void);
void ZGWriteDefaultRecommendedBodyLineLengthLimit(NSUInteger recommendedBodyLineLengthLimit);

void ZGRegisterDefaultRecommendedBodyLineLengthLimitEnabled(void);
BOOL ZGReadDefaultRecommendedBodyLineLengthLimitEnabled(void);
void ZGWriteDefaultRecommendedBodyLineLengthLimitEnabled(BOOL enabled);

void ZGRegisterDefaultAutomaticNewlineInsertionAfterSubjectLine(void);
BOOL ZGReadDefaultAutomaticNewlineInsertionAfterSubjectLine(void);
void ZGWriteDefaultAutomaticNewlineInsertionAfterSubjectLine(BOOL automaticNewlineInsertionAfterSubjectLine);

NS_ASSUME_NONNULL_END
