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

- (void) updateTimeLabel: (UILabel*) label withTime: (int) time
{
    if (time < 0) {
        [label setHidden: YES];
        return;
    }

    [label setHidden: NO];
    [label setText: [NSString stringWithFormat: @"%02d:%02d", time / 60, time % 60]];
}

- (void) updateTime: (NSTimer*) timer
{
    [self updateTimeLabel: timeLabel withTime: [processing time]];
    [self updateTimeLabel: subTimeLabel withTime: [processing subTime]];
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

    if ([processing hasTime]) {
        [self updateTime: nil];
        timer = [[NSTimer scheduledTimerWithTimeInterval: 1
                                                  target: self
                                                selector: @selector (updateTime:)
                                                userInfo: nil
                                                 repeats: YES] retain];
    } else {
        [timeLabel setHidden: YES];
        [subTimeLabel setHidden: YES];
    }

    [cancelButton setTitle: [processing isCancelDestructive] ? @"Cancel" : @"Done"];
}

- (IBAction)cancel:(id)sender
{
    if (![processing isCancelDestructive]) {
        [self finishLearning];
        return;
    }

    [[[UIActionSheet alloc] initWithTitle: @"Really cancel?"
                                 delegate: self
                        cancelButtonTitle: @"No"
                   destructiveButtonTitle: @"Yes"
                        otherButtonTitles: nil] showInView: [self view]];
}

- (void) actionSheet: (UIActionSheet*) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex
{
    if (buttonIndex != [actionSheet destructiveButtonIndex])
        return;
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

    [timer invalidate];
    [timer release];

    [timeLabel release];
    [subTimeLabel release];
    [cancelButton release];

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

    [timer invalidate];
    [timer release];
    timer = nil;

    [processing autorelease];
    processing = nil;

    [cardSet save];

    [cardSet autorelease];
    cardSet = nil;

    [self dismissModalViewControllerAnimated: TRUE];
}

- (void) applicationWillResignActive: (NSNotification*) notification
{
    if (processing == nil)
        return;

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
    NSDictionary *state = [defaults dictionaryForKey: SAVED_STATE_KEY];

    if (state == nil)
        return;

    if ([processing hasTime])
        [processing updateTimeWithState: state];

    [defaults removeObjectForKey: SAVED_STATE_KEY];
    [defaults synchronize];
}

+ (BOOL) hasSavedState
{
    NSDictionary *state = [[NSUserDefaults standardUserDefaults] dictionaryForKey: SAVED_STATE_KEY];
    if (state == nil)
        return NO;
    // FIXME: this is a hack - sometimes the state seems to be saved without a class
    if ([state objectForKey: @"class"] == nil)
        return NO;
    return YES;
}

- (void) restoreFromSavedStateWithCardSet: (CardSet*) cs
{
    NSAssert (!processing, @"Already processing");
    NSAssert (!cardSet, @"Have cardSet");

    cardSet = [cs retain];
}

- (void)viewDidUnload {
    [timeLabel release];
    timeLabel = nil;
    [subTimeLabel release];
    subTimeLabel = nil;
    [cancelButton release];
    cancelButton = nil;
    [super viewDidUnload];
}

@end
