//
//  RepeatProcessing.m
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RepeatProcessing.h"

@implementation RepeatProcessing

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cs
{
    self = [super initWithController: c];
    
    cards = [cs retain];
    index = -1;

    return self;
}

- (void) dealloc
{
    [cards release];
    
    [super dealloc];
}

- (void) start
{
    if (started)
	return;
    [super start];

    [controller setTitle: @"Repeating"];
    [self nextCard];
}

- (void) nextCard
{
    ++index;
    if (index >= [cards count]) {
	[controller finishLearning];
	return;
    }

    [controller askCard: [cards objectAtIndex: index]];
}

- (void) correct
{
    NSLog (@"correct");
    [[[cards objectAtIndex: index] questionSide] nextBatch];
    [self nextCard];
}

- (void) incorrect
{
    NSLog (@"incorrect");
    [[[cards objectAtIndex: index] questionSide] setNew];
    [self nextCard];
}

@end
