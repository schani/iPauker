//
//  XMLParserDelegate.m
//  iPauker
//
//  Created by Mark Probst on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "XMLParserDelegate.h"

enum {
    StateTopLevel,
    StateInBatch,
    StateInCard,
    StateInFrontSide,
    StateInFrontSideText,
    StateInReverseSide,
    StateInReverseSideText
};

@implementation XMLParserDelegate

- (id) init
{
    self = [super init];

    cardSet = [[CardSet alloc] init];
    currentBatch = -1;
    frontSide = backSide = nil;
    state = StateTopLevel;

    return self;
}

- (void) dealloc
{
    [cardSet release];
    [frontSide release];
    [backSide release];

    [super dealloc];
}

- (CardSet*) cardSet
{
    return cardSet;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    if (state == StateTopLevel && [elementName isEqualToString: @"Batch"]) {
	++currentBatch;
	state = StateInBatch;
    } else if (state == StateInBatch && [elementName isEqualToString: @"Card"]) {
	state = StateInCard;
    } else if (state == StateInCard && [elementName isEqualToString: @"FrontSide"]) {
	state = StateInFrontSide;
    } else if (state == StateInFrontSide && [elementName isEqualToString: @"Text"]) {
	if (!frontSide) {
	    frontSide = [[NSMutableString alloc] initWithCapacity: 32];
	} else {
	    NSLog (@"Duplicate front side text");
	}
	state = StateInFrontSideText;
    } else if (state == StateInCard && [elementName isEqualToString: @"ReverseSide"]) {
	state = StateInReverseSide;
    } else if (state == StateInReverseSide && [elementName isEqualToString: @"Text"]) {
	if (!backSide) {
	    backSide = [[NSMutableString alloc] initWithCapacity: 32];
	} else {
	    NSLog (@"Duplicate back side text");
	}
	state = StateInReverseSideText;
    } else if ((state == StateInFrontSide || state == StateInReverseSide) && [elementName isEqualToString: @"Font"]) {
	//nop
    } else {
	NSLog (@"Unexpected start element %@ in state %d", elementName, state);
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if (state == StateInBatch && [elementName isEqualToString: @"Batch"]) {
	state = StateTopLevel;
    } else if (state == StateInCard && [elementName isEqualToString: @"Card"]) {
	if (frontSide && backSide) {
	    [cardSet addCard: [[[Card alloc] initWithFrontSideText: frontSide backSideText: backSide] autorelease]];
	} else {
	    NSLog (@"Card is missing front side or back side");
	}
	[frontSide release];
	[backSide release];
	frontSide = nil;
	backSide = nil;

	state = StateInBatch;
    } else if (state == StateInFrontSide && [elementName isEqualToString: @"FrontSide"]) {
	state = StateInCard;
    } else if (state == StateInReverseSide && [elementName isEqualToString: @"ReverseSide"]) {
	state = StateInCard;
    } else if (state == StateInFrontSideText && [elementName isEqualToString: @"Text"]) {
	state = StateInFrontSide;
    } else if (state == StateInReverseSideText && [elementName isEqualToString: @"Text"]) {
	state = StateInReverseSide;
    } else if ((state == StateInFrontSide || state == StateInReverseSide) && [elementName isEqualToString: @"Font"]) {
	//nop
    } else {
	NSLog (@"Unexpected end element %@ in state %d", elementName, state);
    }
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    if (state == StateInFrontSideText) {
	[frontSide appendString: string];
    } else if (state == StateInReverseSideText) {
	[backSide appendString: string];
    } else {
	//NSLog (@"Extraneous characters `%@' in state %d", string, state);
    }
}

@end
