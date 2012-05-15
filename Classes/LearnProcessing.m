//
//  LearnProcessing.m
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "iPaukerAppDelegate.h"
#import "PreferencesController.h"
#import "NSArray+iPauker.h"

#import "LearnProcessing.h"

@implementation LearnProcessing

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cards
{
    self = [super initWithController: c];

    newCards = [[NSMutableArray arrayWithArray: cards] retain];
    repeatCards = [[NSMutableArray arrayWithCapacity: 16] retain];
    knownCards = [[NSMutableArray arrayWithCapacity: 64] retain];

    return self;
}

- (id) initWithController: (iPaukerLearnViewController*) c
                    state: (NSDictionary*) state
{
    self = [super initWithController: c state: state];
    if (self != nil) {
        CardSet *cs = [c cardSet];

        newCards = [[[state objectForKey: @"newCards"] arrayWithCardsFromCardSet: cs] mutableCopy];
        repeatCards = [[[state objectForKey: @"repeatCards"] arrayWithCardsFromCardSet: cs] mutableCopy];
        knownCards = [[[state objectForKey: @"knownCards"] arrayWithCardsFromCardSet: cs] mutableCopy];
        mode = [[state objectForKey: @"mode"] intValue];
        [self updateTimeWithState: state];
    }
    return self;
}

- (void) dealloc
{
    [newCards release];
    [repeatCards release];
    [knownCards release];

    [super dealloc];
}

- (void) showFrontCard
{
    [controller showCard: [newCards objectAtIndex: 0]];
}

- (void) nextRepeat
{
    NSAssert (mode == MODE_REPEAT_MEMORIZED || mode == MODE_REPEAT_KNOWN, @"nextRepeat must only be called in a repeat mode.");

    if (mode == MODE_REPEAT_MEMORIZED) {
	if ([repeatCards count] == 0) {
	    [self setMemorizeMode];
	    return;
	}

	[controller askCard: [repeatCards objectAtIndex: 0]];
    } else {
	if ([knownCards count] == 0) {
	    [controller finishLearning];
	    return;
	}

	[controller askCard: [knownCards objectAtIndex: 0]];
    }
}

- (BOOL) isMemorizeExpired
{
    long long time = [iPaukerAppDelegate updateAndGetTime];
    NSAssert (mode == MODE_MEMORIZE, @"Not in memorize mode.");
    return time > memorizeStartTime + [[PreferencesController sharedPreferencesController] ultraShortTermMemoryDuration];
}

- (BOOL) isShortTermMemoryExpired
{
    long long time = [iPaukerAppDelegate updateAndGetTime];
    return time > startTime + [[PreferencesController sharedPreferencesController] shortTermMemoryDuration];
}

- (void) setMemorizeMode
{
    if ([newCards count] == 0 || [self isShortTermMemoryExpired]) {
	[self setRepeatKnownMode];
	return;
    }

    mode = MODE_MEMORIZE;

    memorizeStartTime = [iPaukerAppDelegate updateAndGetTime];

    [controller setTitle: @"Memorizing"];
    [self showFrontCard];
}

- (void) setRepeatMemorizedMode
{
    if ([repeatCards count] == 0)
	[self setMemorizeMode];

    mode = MODE_REPEAT_MEMORIZED;

    [controller setTitle: @"Ultrashort-Term Memory"];
    [self nextRepeat];
}

- (void) setRepeatKnownMode
{
    if ([knownCards count] == 0) {
	[controller finishLearning];
	return;
    }

    mode = MODE_REPEAT_KNOWN;

    [controller setTitle: @"Short-Term Memory"];
    [self nextRepeat];

}

- (void) start
{
    if (started)
	return;
    [super start];

    startTime = [iPaukerAppDelegate updateAndGetTime];

    [self setMemorizeMode];
}

- (void) correct
{
    Card *card;

    NSAssert (mode == MODE_REPEAT_MEMORIZED || mode == MODE_REPEAT_KNOWN, @"Correct can only be pressed in a repeat mode.");

    if (mode == MODE_REPEAT_MEMORIZED) {
	card = [repeatCards objectAtIndex: 0];
	[knownCards addObject: card];
	[repeatCards removeObjectAtIndex: 0];
    } else {
	card = [knownCards objectAtIndex: 0];
	[[card questionSide] setLearned];
	[knownCards removeObjectAtIndex: 0];
    }

    [self nextRepeat];
}

- (void) incorrect
{
    Card *card;

    NSAssert (mode == MODE_REPEAT_MEMORIZED || mode == MODE_REPEAT_KNOWN, @"Incorrect can only be pressed in a repeat mode.");

    if (mode == MODE_REPEAT_MEMORIZED) {
	card = [repeatCards objectAtIndex: 0];
	[newCards insertObject: card atIndex: 0];
	[repeatCards removeObjectAtIndex: 0];
    } else {
	card = [knownCards objectAtIndex: 0];
	[knownCards removeObjectAtIndex: 0];
    }

    [self nextRepeat];
}

- (void) next
{
    Card *card = [newCards objectAtIndex: 0];
    [repeatCards addObject: card];
    [newCards removeObjectAtIndex: 0];

    NSAssert (mode == MODE_MEMORIZE, @"Next can only be pressed in memorize mode.");

    if ([newCards count] == 0 || [self isMemorizeExpired]) {
	[self setRepeatMemorizedMode];
	return;
    }

    [self showFrontCard];
}

- (NSDictionary*) state
{
    long long time = [iPaukerAppDelegate updateAndGetTime];
    NSMutableDictionary *state = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [newCards arrayWithCardKeys], @"newCards",
                                  [repeatCards arrayWithCardKeys], @"repeatCards",
                                  [knownCards arrayWithCardKeys], @"knownCards",
                                  [NSNumber numberWithInt: mode], @"mode",
                                  [NSNumber numberWithLongLong: time - startTime], @"startTime",
                                  [NSNumber numberWithLongLong: time - memorizeStartTime], @"memorizeStartTime",
                                  nil];
    [state addEntriesFromDictionary: [super state]];
    return state;
}

- (BOOL) hasTime
{
    return YES;
}

- (void) updateTimeWithState: (NSDictionary*) state
{
    long long time = [iPaukerAppDelegate updateAndGetTime];

    startTime = time - [[state objectForKey: @"startTime"] longLongValue];
    memorizeStartTime = time - [[state objectForKey: @"memorizeStartTime"] longLongValue];
}

- (int) timeTo: (long long) duration since: (long long) start
{
    long long time = [iPaukerAppDelegate updateAndGetTime];
    long long passed = time - start;
    int rest = (duration - passed) / 1000;
    if (rest < 0)
        return 0;
    return rest;
}

- (int) time
{
    if (mode == MODE_REPEAT_KNOWN)
        return -1;
    return [self timeTo: [[PreferencesController sharedPreferencesController] shortTermMemoryDuration]
                  since: startTime];
}

- (int) subTime
{
    if (mode != MODE_MEMORIZE)
        return -1;
    return [self timeTo: [[PreferencesController sharedPreferencesController] ultraShortTermMemoryDuration]
                  since: memorizeStartTime];
}

- (int) cardCount
{
    if (mode == MODE_REPEAT_MEMORIZED)
        return [repeatCards count];
    if (mode == MODE_REPEAT_KNOWN)
        return [knownCards count];
    return -1;
}

@end
