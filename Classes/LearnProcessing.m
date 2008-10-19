//
//  LearnProcessing.m
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LearnProcessing.h"

@implementation LearnProcessing

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cards
{
    self = [super initWithController: c];

    newCards = [[NSMutableArray arrayWithArray: cards] retain];
    repeatCards = [[NSMutableArray arrayWithCapacity: 16] retain];
    knownCards = [[NSMutableArray arrayWithCapacity: 64] retain];
    
    repeatingKnown = NO;
    
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

- (void) start
{
    if (started)
	return;
    [super start];

    [controller setTitle: @"Memorizing"];
    [self showFrontCard];
}

- (void) nextRepeat
{
    if (repeatingKnown) {
	if ([knownCards count] == 0) {
	    [controller finishLearning];
	    return;
	}
	
	[controller askCard: [knownCards objectAtIndex: 0]];
    } else {
	if ([repeatCards count] == 0) {
	    if ([newCards count] == 0) {
		repeatingKnown = YES;
		[controller setTitle: @"Short-Term Memory"];
		[self nextRepeat];
	    } else {
		[controller setTitle: @"Memorizing"];
		[self showFrontCard];
	    }
	    return;
	}
	
	[controller askCard: [repeatCards objectAtIndex: 0]];
    }
}

- (void) correct
{
    Card *card;

    if (repeatingKnown) {
	card = [knownCards objectAtIndex: 0];
	[knownCards removeObjectAtIndex: 0];
	[[card questionSide] nextBatch];
    } else {
	card = [repeatCards objectAtIndex: 0];
	[repeatCards removeObjectAtIndex: 0];
	[knownCards addObject: card];
    }
    
    [self nextRepeat];
}

- (void) incorrect
{
    Card *card;

    if (repeatingKnown) {
	card = [knownCards objectAtIndex: 0];
	[knownCards removeObjectAtIndex: 0];
    } else {
	card = [repeatCards objectAtIndex: 0];
	[repeatCards removeObjectAtIndex: 0];
	[newCards insertObject: card atIndex: 0];
    }

    [self nextRepeat];
}

- (void) next
{
    Card *card = [newCards objectAtIndex: 0];
    [newCards removeObjectAtIndex: 0];
    [repeatCards addObject: card];

    if ([newCards count] == 0) {
	if ([repeatCards count] == 0) {
	    repeatingKnown = YES;
	    [controller setTitle: @"Short-Term Memory"];
	} else {
	    [controller setTitle: @"Ultrashort-Term Memory"];
	}
	[self nextRepeat];
	return;
    }
    
    [self showFrontCard];
}

@end
