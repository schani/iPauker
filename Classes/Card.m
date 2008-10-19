//
//  Card.m
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Card.h"


@implementation Card

- (id) initWithFrontText: (NSString*) ft
	      frontBatch: (int) fb
	  frontTimestamp: (long long) fts
	     reverseText: (NSString*) rt
	    reverseBatch: (int) rb
	reverseTimestamp: (long long) rts
{
    self = [super init];
    
    cardSet = nil;
    frontSide = [[CardSide alloc] initForCard: self withText: ft batch: fb timestamp: fts];
    reverseSide = [[CardSide alloc] initForCard: self withText: rt batch: rb timestamp: rts];

    return self;
}

- (void) dealloc
{
    [frontSide release];
    [reverseSide release];
    
    [super dealloc];
}

- (void) setCardSet: (CardSet*) cs
{
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

@end
