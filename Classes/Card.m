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

- (BOOL) isChanged
{
    return [frontSide isChanged] || [reverseSide isChanged];
}

- (void) setNotChanged
{
    [frontSide setChanged: NO];
    [reverseSide setChanged: NO];
}

- (int) key
{
    return key;
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
