//
//  Card.m
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSStringAdditions.h"

#import "Card.h"

@implementation Card

- (id) initWithFrontText: (NSString*) ft
	      frontBatch: (int) fb
	  frontTimestamp: (long long) fts
	     reverseText: (NSString*) rt
	    reverseBatch: (int) rb
	reverseTimestamp: (long long) rts
		     key: (int) k
{
    self = [super init];
    
    cardSet = nil;
    frontSide = [[CardSide alloc] initForCard: self withText: ft batch: fb timestamp: fts];
    reverseSide = [[CardSide alloc] initForCard: self withText: rt batch: rb timestamp: rts];
    key = k;
    changed = NO;

    return self;
}

- (void) dealloc
{
    [frontSide release];
    [reverseSide release];
    
    [super dealloc];
}

- (Card*) copy
{
    Card *card = [[[Card alloc] initWithFrontText: [frontSide text]
				       frontBatch: [frontSide batch]
				   frontTimestamp: [frontSide timestamp]
				      reverseText: [reverseSide text]
				     reverseBatch: [reverseSide batch]
				 reverseTimestamp: [reverseSide timestamp]
					      key: key] autorelease];
    if (changed)
        [card setChangedAndDirty: NO];
    return card;
}

- (void) setCardSet: (CardSet*) cs
{
    if (cs)
	NSAssert (!cardSet, @"Can only set card set once.");
    cardSet = cs;
}

- (CardSet*) cardSet
{
    return cardSet;
}

- (CardSide*) questionSide
{
    return [cardSet isFlipped] ? reverseSide : frontSide;
}

- (CardSide*) answerSide
{
    return [cardSet isFlipped] ? frontSide : reverseSide;
}

- (NSString*) question
{
    return [[self questionSide] text];
}

- (NSString*) answer
{
    return [[self answerSide] text];
}

- (CardSide*) frontSide
{
    return frontSide;
}

- (CardSide*) reverseSide
{
    return reverseSide;
}

- (BOOL) isChanged
{
    return changed;
}

- (void) setChangedAndDirty: (BOOL) setDirty
{
    if (setDirty) {
        NSAssert (cardSet != nil, @"Cannot set dirty without card set");
        [cardSet setCardDirty: self];
    }

    changed = YES;
}

- (void) setNotChanged
{
    if (!changed)
	return;

    changed = NO;
    if (cardSet)
	[cardSet setCardDirty: self];
}

- (int) key
{
    return key;
}

- (void) setKey: (int) _key
{
    key = _key;
}

- (BOOL) isEqual: (id) obj
{
    Card *card;
    if (![obj isKindOfClass: [Card class]])
	return NO;
    card = (Card*)obj;
    return [[frontSide text] isEqual: [card->frontSide text]] && [[reverseSide text] isEqual: [card->reverseSide text]];
}

- (void) writeXMLToString: (NSMutableString*) string
{
    [string appendFormat: @"<card><front batch=\"%d\"", [frontSide batch]];
    if ([frontSide timestamp] <= 0)
	[string appendString: @">"];
    else
	[string appendFormat: @" timestamp=\"%lld\">", [frontSide timestamp]];
    [string appendFormat: @"%@</front><reverse batch=\"%d\"", [[frontSide text] XMLEncode], [reverseSide batch]];
    if ([reverseSide timestamp] <= 0)
	[string appendString: @">"];
    else
	[string appendFormat: @" timestamp=\"%lld\">", [reverseSide timestamp]];
    [string appendFormat: @"%@</reverse></card>\n", [[reverseSide text] XMLEncode]];
}

@end
