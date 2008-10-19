//
//  CardSet.m
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CardSet.h"
#import "Card.h"
#import "iPaukerAppDelegate.h"

@implementation CardSet

- (id) init
{
    self = [super init];
    
    isFlipped = FALSE;
    cards = [[NSMutableArray arrayWithCapacity: 32] retain];

    countsCurrent = NO;
    
    return self;
}

- (void) dealloc
{
    [cards release];

    [super dealloc];
}

- (void) addCard: (Card*) card
{
    [cards addObject: card];
    [card setCardSet: self];
}

- (int) numTotalCards
{
    return [cards count];
}

- (void) countCards
{
    NSEnumerator *enumerator;
    Card *card;

    [(iPaukerAppDelegate*)[[UIApplication sharedApplication] delegate] updateTime];

    if (countsCurrent)
	return;

    numExpiredCards = 0;
    numNewCards = 0;
    numLearnedCards = 0;

    enumerator = [cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	CardSide *side = [card questionSide];

	if ([side isNew])
	    ++numNewCards;
	else if ([side isExpired])
	    ++numExpiredCards;
	else
	    ++numLearnedCards;
    }
}

- (int) numExpiredCards
{
    [self countCards];
    return numExpiredCards;
}

- (int) numNewCards
{
    [self countCards];
    return numNewCards;
}

- (int) numLearnedCards
{
    [self countCards];
    return numLearnedCards;
}

- (BOOL) isFlipped
{
    return isFlipped;
}

- (NSArray*) newCards
{
    NSMutableArray *new = [NSMutableArray arrayWithCapacity: [cards count] / 2];
    NSEnumerator *enumerator;
    Card *card;

    enumerator = [cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	CardSide *side = [card questionSide];

	if ([side isNew])
	    [new addObject: card];
    }
    
    return new;
}

- (NSArray*) expiredCards
{
    NSMutableArray *expired = [NSMutableArray arrayWithCapacity: [cards count] / 2];
    NSEnumerator *enumerator;
    Card *card;

    [(iPaukerAppDelegate*)[[UIApplication sharedApplication] delegate] updateTime];
    
    enumerator = [cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	CardSide *side = [card questionSide];

	if (![side isNew] && [side isExpired])
	    [expired addObject: card];
    }

    return expired;
}

- (NSArray*) changedCards
{
    NSMutableArray *changed = [NSMutableArray arrayWithCapacity: [cards count] / 10];
    NSEnumerator *enumerator;
    Card *card;
    
    enumerator = [cards objectEnumerator];
    while (card = [enumerator nextObject])
	if ([card isChanged])
	    [changed addObject: card];

    return changed;
}

- (void) cardsMoved
{
    countsCurrent = FALSE;
}

@end
