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
#import "DatabaseController.h"

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

    addedCards = [[NSMutableSet setWithCapacity: 8] retain];
    dirtyCards = [[NSMutableSet setWithCapacity: 8] retain];
    deletedCards = [[NSMutableSet setWithCapacity: 8] retain];

    return self;
}

- (void) dealloc
{
    [cards release];
    [name release];
    [addedCards release];
    [dirtyCards release];
    [deletedCards release];

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

- (void) addCard: (Card*) card dirty: (BOOL) dirty
{
    if ([card cardSet])
	card = [card copy];
    [cards addObject: card];
    [card setCardSet: self];
    
    if ([card key] > highestKey)
	highestKey = [card key];
    
    if (dirty)
	[addedCards addObject: card];
}

- (void) setCardDirty: (Card*) card
{
    [dirtyCards addObject: card];
}

- (void) replaceCardAtIndex: (NSUInteger) index withCard: (Card*) card
{
    Card *oldCard = [cards objectAtIndex: index];

    if ([card cardSet])
	card = [card copy];

    [card setKey: [oldCard key]];
    [oldCard setCardSet: nil];

    [cards replaceObjectAtIndex: index withObject: card];
    [self setCardDirty: card];
}

- (void) removeCardAtIndex: (NSUInteger) index
{
    Card *card = [cards objectAtIndex: index];

    NSAssert ([card cardSet] == self, @"Card has the wrong card set.");

    [deletedCards addObject: card];

    [cards removeObjectAtIndex: index];
    [card setCardSet: nil];
}

- (void) updateWithDeletedCardSet: (CardSet*) dcs cardSet: (CardSet*) cs;
{
    NSEnumerator *enumerator;
    Card *card;

    enumerator = [dcs->cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	NSUInteger index = [cards indexOfObject: card];
	/*
	 * It could happen that we get a delete updated for a card
	 * that we don't know about because it was created and deleted
	 * since the last update
	 */
	if (index != NSNotFound)
	    [self removeCardAtIndex: index];
    }
    
    enumerator = [cs->cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	NSUInteger index = [cards indexOfObject: card];
	NSAssert(![card isChanged], @"New card is marked as changed");
	if (index == NSNotFound) {
	    [card setKey: [self newKey]];
	    [self addCard: card dirty: YES];
	} else {
	    [self replaceCardAtIndex: index withCard: card];
	}
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

- (void) save
{
    DatabaseController *db = [DatabaseController sharedDatabaseController];

    NSDate *date = [NSDate date];
    NSLog (@"inserting %d cards", [addedCards count]);
    [db insertCards: addedCards forLesson: name];
    [addedCards removeAllObjects];

    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate: date];
    NSLog (@"inserting took %.2f seconds", interval);

    date = [NSDate date];
    NSLog (@"updating %d cards", [dirtyCards count]);
    [db updateCards: dirtyCards forLesson: name];
    [dirtyCards removeAllObjects];
    interval = [[NSDate date] timeIntervalSinceDate: date];
    NSLog (@"updating took %.2f seconds", interval);

    date = [NSDate date];
    NSLog (@"deleting %d cards", [deletedCards count]);
    [db deleteCards: deletedCards forLesson: name];
    [deletedCards removeAllObjects];
    interval = [[NSDate date] timeIntervalSinceDate: date];
    NSLog (@"deleting took %.2f seconds", interval);
}

- (void) benchmarkWithNumberOfCards: (int) numberOfCards
{
    int i = 0;
    for (Card *card in cards) {
        [self setCardDirty: card];
        if (++i >= numberOfCards)
            break;
    }
    [self save];
}

@end
