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
    
    if (isLoaded && processing)
	[processing start];
}

- (IBAction)cancel:(id)sender {
    [self finishLearning];
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
}
 */


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}

- (BOOL) learnNewFromCardSet: (CardSet*) cardSet
{
    NSArray *cards;
    
    NSAssert (!processing, @"Already processing");

    cards = [cardSet newCards];

    if ([cards count] == 0)
	return NO;

    processing = [[LearnProcessing alloc] initWithController: self cards: cards];
    
    return YES;
}

- (BOOL) repeatExpiredFromCardSet: (CardSet*) cardSet
{
    NSArray *cards;

    NSAssert (!processing, @"Already processing");

    cards = [cardSet expiredCards];

    if ([cards count] == 0)
	return NO;

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

    [self dismissModalViewControllerAnimated: TRUE];
}

@end
