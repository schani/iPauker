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
    StateInCard,
    StateInSide
};

@implementation XMLParserDelegate

- (id) initWithLessonName: (NSString*) name
{
    self = [super init];

    cardSet = [[CardSet alloc] initWithName: name];
    deletedCardSet = [[CardSet alloc] initWithName: name];
    state = StateTopLevel;
    
    frontBatch = reverseBatch = -1;
    text = nil;
    frontText = reverseText = nil;
    frontTimestamp = reverseTimestamp = -1;

    return self;
}

- (void) dealloc
{
    [cardSet release];
    [deletedCardSet release];
    [frontText release];
    [reverseText release];

    [super dealloc];
}

- (CardSet*) cardSet
{
    return cardSet;
}

- (CardSet*) deletedCardSet
{
    return deletedCardSet;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    if (state == StateTopLevel && [elementName isEqualToString: @"cards"]) {
	if ([attributeDict valueForKey: @"version"])
	    [cardSet setVersion: [[attributeDict valueForKey: @"version"] intValue]];
    } else if (state == StateTopLevel && [elementName isEqualToString: @"card"]) {
	state = StateInCard;
	if ([attributeDict valueForKey: @"deleted"]
	    && [[attributeDict valueForKey: @"deleted"] isEqualToString: @"True"])
	    deleted = YES;
	else
	    deleted = NO;
    } else if (state == StateInCard && [elementName isEqualToString: @"front"]) {
	frontBatch = [[attributeDict valueForKey: @"batch"] intValue];
	if ([attributeDict valueForKey: @"timestamp"]
	    && ![[attributeDict valueForKey: @"timestamp"] isEqualToString: @"None"])
	    frontTimestamp = [[attributeDict valueForKey: @"timestamp"] longLongValue];
	else
	    frontTimestamp = -1;
	text = [[NSMutableString string] retain];
	state = StateInSide;
    } else if (state == StateInCard && [elementName isEqualToString: @"reverse"]) {
	reverseBatch = [[attributeDict valueForKey: @"batch"] intValue];
	if ([attributeDict valueForKey: @"timestamp"]
	    && ![[attributeDict valueForKey: @"timestamp"] isEqualToString: @"None"])
	    reverseTimestamp = [[attributeDict valueForKey: @"timestamp"] longLongValue];
	else
	    reverseTimestamp = -1;
	text = [[NSMutableString string] retain];
	state = StateInSide;
    } else {
	//NSLog (@"Unexpected start element %@ in state %d", elementName, state);
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if (state == StateInCard && [elementName isEqualToString: @"card"]) {
	CardSet *set = deleted ? deletedCardSet : cardSet;

	[set addCard: [[[Card alloc] initWithFrontText: frontText
					    frontBatch: frontBatch
					frontTimestamp: frontTimestamp
					   reverseText: reverseText
					  reverseBatch: reverseBatch
				      reverseTimestamp: reverseTimestamp
						   key: [cardSet newKey]] autorelease]
	       dirty: NO];
	state = StateTopLevel;
    } else if (state == StateInSide && [elementName isEqualToString: @"front"]) {
	frontText = text;
	text = nil;
	state = StateInCard;
    } else if (state == StateInSide && [elementName isEqualToString: @"reverse"]) {
	reverseText = text;
	text = nil;
	state = StateInCard;
    }
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    if (state == StateInSide)
	[text appendString: string];
}

@end
