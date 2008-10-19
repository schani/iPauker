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

- (id) init
{
    self = [super init];

    cardSet = [[CardSet alloc] init];
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
    [frontText release];
    [reverseText release];

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
    if (state == StateTopLevel && [elementName isEqualToString: @"card"]) {
	state = StateInCard;
    } else if (state == StateInCard && [elementName isEqualToString: @"front"]) {
	frontBatch = [[attributeDict valueForKey: @"batch"] intValue];
	if ([attributeDict valueForKey: @"timestamp"])
	    frontTimestamp = [[attributeDict valueForKey: @"timestamp"] longLongValue];
	else
	    frontTimestamp = -1;
	text = [[NSMutableString string] retain];
	state = StateInSide;
    } else if (state == StateInCard && [elementName isEqualToString: @"reverse"]) {
	reverseBatch = [[attributeDict valueForKey: @"batch"] intValue];
	if ([attributeDict valueForKey: @"timestamp"])
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
	[cardSet addCard: [[[Card alloc] initWithFrontText: frontText
						frontBatch: frontBatch
					    frontTimestamp: frontTimestamp
					       reverseText: reverseText
					      reverseBatch: reverseBatch
					  reverseTimestamp: reverseTimestamp] autorelease]];
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
