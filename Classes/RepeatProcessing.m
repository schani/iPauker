//
//  RepeatProcessing.m
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSArray+iPauker.h"

#import "RepeatProcessing.h"

@implementation RepeatProcessing

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cs
{
    self = [super initWithController: c];
    
    cards = [cs retain];
    index = -1;

    return self;
}

- (id) initWithController: (iPaukerLearnViewController*) c
                    state: (NSDictionary*) state
{
    self = [super initWithController: c state: state];
    if (self != nil) {
        index = [[state objectForKey: @"index"] intValue];
        cards = [[[state objectForKey: @"cards"] arrayWithCardsFromCardSet: [c cardSet]] retain];
    }
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

- (BOOL) isCancelDestructive
{
    return NO;
}

- (NSDictionary*) state
{
    NSMutableDictionary *state = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                  [NSNumber numberWithInt: index], @"index",
                                  [cards arrayWithCardKeys], @"cards",
                                  nil];
    [state addEntriesFromDictionary: [super state]];
    return state;
}

- (int) cardCount
{
    return [cards count] - index;
}

@end
