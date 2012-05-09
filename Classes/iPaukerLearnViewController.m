//
//  iPaukerLearnViewController.m
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "iPaukerLearnViewController.h"
#import "RepeatProcessing.h"
#import "LearnProcessing.h"

#define SAVED_STATE_KEY @"iPaukerLearnViewController.state"

@implementation iPaukerLearnViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
	isLoaded = NO;
    }
    return self;
}

- (void) viewDidLoad
{
    NSLog (@"did load");
    isLoaded = YES;
}

- (void) viewWillAppear: (BOOL) animated
{
    NSLog (@"will appear");

    [super viewWillAppear: animated];

    if (!isLoaded)
        return;

    if (processing == nil) {
        NSAssert (cardSet != nil, @"Cannot learn without a card set");

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *state = [defaults dictionaryForKey: SAVED_STATE_KEY];
        NSAssert (state != nil, @"No saved state");
        [defaults removeObjectForKey: SAVED_STATE_KEY];

        [showButton setTitle: [state objectForKey: @"showButtonTitle"]];
        [questionText setText: [state objectForKey: @"questionText"]];
        [answerText setText: [state objectForKey: @"answerText"]];
        [showButton setEnabled: [[state objectForKey: @"showButtonEnabled"] boolValue]];
        [correctButton setEnabled: [[state objectForKey: @"correctButtonEnabled"] boolValue]];
        [incorrectButton setEnabled: [[state objectForKey: @"incorrectButtonEnabled"] boolValue]];
        NSNumber *key = [state objectForKey: @"card"];
        if (key != nil) {
            card = [[cardSet cardForKey: [key intValue]] retain];
            NSAssert (card != nil, @"Saved card not found");
        }

        processing = [[CardProcessing cardProcessingWithController: self state: state] retain];
    }

	[processing start];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (applicationWillResignActive:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (applicationDidBecomeActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    NSLog (@"registered for termination");
}

- (IBAction)cancel:(id)sender {
    [self finishLearning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
    // FIXME: implement!
	[super dealloc];
}

- (CardSet*) cardSet
{
    return cardSet;
}

- (BOOL) learnNewFromCardSet: (CardSet*) _cardSet
{
    NSArray *cards;

    NSAssert (!processing, @"Already processing");
    NSAssert (!cardSet, @"Have cardSet");

    cards = [_cardSet newCards];
    if ([cards count] == 0)
	return NO;

    cardSet = [_cardSet retain];

    processing = [[LearnProcessing alloc] initWithController: self cards: cards];

    return YES;
}

- (BOOL) repeatExpiredFromCardSet: (CardSet*) _cardSet
{
    NSArray *cards;

    NSAssert (!processing, @"Already processing");
    NSAssert (!cardSet, @"Have cardSet");

    cards = [_cardSet expiredCards];
    if ([cards count] == 0)
	return NO;

    cardSet = [_cardSet retain];

    processing = [[RepeatProcessing alloc] initWithController: self cards: cards];

    return YES;
}

- (IBAction)show:(id)sender
{
    if (card) {
	[answerText setText: [card answer]];
	
	[showButton setEnabled: NO];
	[correctButton setEnabled: YES];
	[incorrectButton setEnabled: YES];
	
	[card release];
	card = nil;
    } else {
	[processing next];
    }
}

- (IBAction)correct:(id)sender
{
    [processing correct];
}

- (IBAction)incorrect:(id)sender
{
    [processing incorrect];
}

- (void) askCard: (Card*) c
{
    NSAssert (!card, @"Already asking a card");
    
    card = [c retain];

    [showButton setTitle: @"Show"];

    [questionText setText: [card question]];
    [answerText setText: @"?"];

    [showButton setEnabled: YES];
    [correctButton setEnabled: NO];
    [incorrectButton setEnabled: NO];    
}

- (void) showCard: (Card*) c
{
    NSAssert (!card, @"Already asking a card");
    
    [showButton setTitle: @"Next"];
    
    [questionText setText: [c question]];
    [answerText setText: [c answer]];
    
    [showButton setEnabled: YES];
    [correctButton setEnabled: NO];
    [incorrectButton setEnabled: NO];
}

- (void) finishLearning
{
    NSAssert (processing, @"Not processing");
    
    if (card) {
	[card autorelease];
	card = nil;
    }
    
    [processing autorelease];
    processing = nil;

    [cardSet save];

    [cardSet autorelease];
    cardSet = nil;

    [self dismissModalViewControllerAnimated: TRUE];
}

- (void) applicationWillResignActive: (NSNotification*) notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *state = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [showButton title], @"showButtonTitle",
                                  [questionText text], @"questionText",
                                  [answerText text], @"answerText",
                                  [NSNumber numberWithBool: [showButton isEnabled]], @"showButtonEnabled",
                                  [NSNumber numberWithBool: [correctButton isEnabled]], @"correctButtonEnabled",
                                  [NSNumber numberWithBool: [incorrectButton isEnabled]], @"incorrectButtonEnabled",
                                  nil];
    if (card != nil)
        [state setObject: [NSNumber numberWithInt: [card key]] forKey: @"card"];
    [state addEntriesFromDictionary: [processing state]];

    [defaults setObject: state forKey: SAVED_STATE_KEY];
    [defaults synchronize];

    NSLog (@"state saved");
}

- (void) applicationDidBecomeActive: (NSNotification*) notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey: SAVED_STATE_KEY];
    [defaults synchronize];
}

+ (BOOL) hasSavedState
{
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey: SAVED_STATE_KEY] != nil;
}

- (void) restoreFromSavedStateWithCardSet: (CardSet*) cs
{
    NSAssert (!processing, @"Already processing");
    NSAssert (!cardSet, @"Have cardSet");

    cardSet = [cs retain];
}

@end
