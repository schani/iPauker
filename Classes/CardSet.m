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
#import "PreferencesController.h"

@implementation CardSet

- (id) initWithName: (NSString*) cardSetName
{
    self = [super init];
    
    name = [cardSetName retain];
    version = [[PreferencesController sharedPreferencesController] versionOfLesson: name];

    isFlipped = FALSE;
    cards = [[NSMutableArray arrayWithCapacity: 32] retain];

    countsCurrent = NO;
    highestKey = -1;

    return self;
}

- (void) dealloc
{
    [cards release];
    [name release];

    [super dealloc];
}

- (int) version
{
    return version;
}

- (void) setVersion: (int) newVersion
{
    version = newVersion;
}

- (void) addCard: (Card*) card
{
    [cards addObject: card];
    [card setCardSet: self];
    
    if ([card key] > highestKey)
	highestKey = [card key];
}

- (void) replaceCardAtIndex: (NSUInteger) index withCard: (Card*) card
{
    Card *oldCard = [cards objectAtIndex: index];
    
    [card setKey: [oldCard key]];
    [cards replaceObjectAtIndex: index withObject: card];
}

- (void) removeCardAtIndex: (NSUInteger) index
{
    [cards removeObjectAtIndex: index];
}

- (void) updateWithDeletedCardSet: (CardSet*) dcs cardSet: (CardSet*) cs;
{
    NSEnumerator *enumerator;
    Card *card;

    enumerator = [dcs->cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	NSUInteger index = [cards indexOfObject: card];
	NSAssert(index != NSNotFound, @"Deleted card is already gone");
	[self removeCardAtIndex: index];
    }
    
    enumerator = [cs->cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	NSUInteger index = [cards indexOfObject: card];
	NSAssert(![card isChanged], @"New card is marked as changed");
	if (index == NSNotFound)
	    [self addCard: card];
	else
	    [self replaceCardAtIndex: index withCard: card];
    }
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

- (int) newKey
{
    return ++highestKey;
}

@end
