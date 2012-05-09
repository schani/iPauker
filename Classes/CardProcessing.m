//
//  CardProcessing.m
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CardProcessing.h"

#import "LearnProcessing.h"
#import "RepeatProcessing.h"

@implementation CardProcessing

+ (id) cardProcessingWithController: (iPaukerLearnViewController*) c
                              state: (NSDictionary*) state
{
    NSString *className = [state objectForKey: @"class"];

    if ([className isEqualToString: @"LearnProcessing"])
        return [[[LearnProcessing alloc] initWithController: c state: state] autorelease];
    if ([className isEqualToString: @"RepeatProcessing"])
        return [[[RepeatProcessing alloc] initWithController: c state: state] autorelease];

    NSAssert (NO, @"Unknown card processing class");
    return NO;
}

- (id) initWithController: (iPaukerLearnViewController*) c
{
    self = [super init];
    
    controller = c;
    started = NO;
    
    return self;
}

- (id) initWithController: (iPaukerLearnViewController*) c
                    state: (NSDictionary*) state
{
    self = [super init];
    if (self != nil) {
        controller = c;
        started = YES;
    }
    return self;
}

- (void) start
{
    started = YES;
}

- (void) next
{
    [self doesNotRecognizeSelector: _cmd];
}

- (void) correct
{
    [self doesNotRecognizeSelector: _cmd];
}

- (void) incorrect
{
    [self doesNotRecognizeSelector: _cmd];
}

- (NSDictionary*) state
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            NSStringFromClass ([self class]), @"class",
            nil];
}

- (BOOL) hasTime
{
    return NO;
}

- (int) time
{
    [self doesNotRecognizeSelector: _cmd];
    return -1;
}

- (int) subTime
{
    [self doesNotRecognizeSelector: _cmd];
    return -1;
}

@end
