#import "ConnectionController.h"
#import "XMLParserDelegate.h"

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

- (void) startDownload
{
    [[ConnectionController sharedConnectionController] startDownloadAndNotify: self];
}

- (IBAction) settings: (id) sender
{
    NSLog(@"settings");
}

- (IBAction) update: (id) sender
{
    NSArray *changed = [cardSet changedCards];
    NSMutableString *string = [NSMutableString string];
    NSEnumerator *enumerator;
    Card *card;

    [string appendString: @"<cards format=\"0.1\">\n"];
    enumerator = [changed objectEnumerator];
    while (card = [enumerator nextObject])
	[card writeXMLToString: string];
    [string appendString: @"</cards>"];
    
    NSLog(@"%@", string);
    [[ConnectionController sharedConnectionController] updateLesson: @"bla" withStringData: string];
}

- (IBAction) learnNew: (id) sender {
    if (!cardSet)
	return;

    [self loadLearnViewController];

    if ([learnViewController learnNewFromCardSet: cardSet])
	[self presentModalViewController: learnViewController animated: TRUE];
}

- (IBAction) repeatExpired: (id) sender {
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

- (void) downloadFinishedWithData: (NSData*) downloadData
{
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData: downloadData] autorelease];
    XMLParserDelegate *delegate = [[[XMLParserDelegate alloc] init] autorelease];

    [parser setDelegate: delegate];
    [parser setShouldProcessNamespaces: NO];
    [parser setShouldReportNamespacePrefixes: NO];
    [parser setShouldResolveExternalEntities: NO];

    [parser parse];

    NSError *parseError = [parser parserError];
    if (parseError) {
	NSLog (@"XML parse error: %@", [parseError localizedDescription]);
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    } else {
	NSLog (@"Parsed XML");
    }

    [self setCardSet: [delegate cardSet]];
}

- (void) downloadFailed
{
    NSLog(@"Download failed");
}

@end
