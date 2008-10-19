#import "iPaukerViewController.h"

@implementation iPaukerViewController

- (void) viewWillAppear: (BOOL) animated
{
    NSLog (@"main view will appear");

    [super viewWillAppear: animated];

    if (cardSet)
	[self updateStats];
}

- (void) dealloc
{
    [cardSet release];
    [learnViewController release];
    [super dealloc];
}

- (void) loadLearnViewController
{
    if (!learnViewController)
	learnViewController = [[iPaukerLearnViewController alloc] initWithNibName: @"iPaukerLearnViewController"
									   bundle: nil];
}

- (IBAction)settings:(id)sender
{
    NSLog(@"settings");
}

- (IBAction)update:(id)sender
{
    NSArray *changed = [cardSet changedCards];

    NSLog(@"update: %d changed", [changed count]);
}

- (IBAction)learnNew:(id)sender {
    if (!cardSet)
	return;

    [self loadLearnViewController];

    if ([learnViewController learnNewFromCardSet: cardSet])
	[self presentModalViewController: learnViewController animated: TRUE];
}

- (IBAction)repeatExpired:(id)sender {
    if (!cardSet)
	return;
    
    [self loadLearnViewController];

    if ([learnViewController repeatExpiredFromCardSet: cardSet])
	[self presentModalViewController: learnViewController animated: TRUE];
}

- (void) updateStats
{
    [totalLabel setText: [NSString stringWithFormat: @"%d", [cardSet numTotalCards]]];
    [expiredLabel setText: [NSString stringWithFormat: @"%d", [cardSet numExpiredCards]]];
    [learnedLabel setText: [NSString stringWithFormat: @"%d", [cardSet numLearnedCards]]];
    [newLabel setText: [NSString stringWithFormat: @"%d", [cardSet numNewCards]]];
}

- (void) setCardSet: (CardSet*) cs
{
    cardSet = [cs retain];
    [self updateStats];
}

@end
