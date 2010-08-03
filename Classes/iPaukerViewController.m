#import "ConnectionController.h"
#import "XMLParserDelegate.h"
#import "DatabaseController.h"
#import "PreferencesController.h"

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

- (void) loadLesson
{
    PreferencesController *prefs = [PreferencesController sharedPreferencesController];

    NSLog(@"version is %d", [prefs versionOfLesson: [prefs mainLessonName]]);
    [self setCardSet: [[DatabaseController sharedDatabaseController] loadLesson: [prefs mainLessonName]]];
}

- (IBAction) settings: (id) sender
{
    NSLog(@"settings");
}

- (void) disableAllButtons
{
    [learnNewButton setEnabled: NO];
    [repeatButton setEnabled: NO];
    [updateButton setEnabled: NO];
}

- (void) enableAllButtons
{
    [learnNewButton setEnabled: YES];
    [repeatButton setEnabled: YES];
    [updateButton setEnabled: YES];
}

- (IBAction) update: (id) sender
{
    NSArray *changed = [cardSet changedCards];
    NSMutableString *string = [NSMutableString string];
    NSEnumerator *enumerator;
    Card *card;

    [self disableAllButtons];
    
    [string appendString: @"<cards format=\"0.1\">\n"];
    enumerator = [changed objectEnumerator];
    while (card = [enumerator nextObject])
	[card writeXMLToString: string];
    [string appendString: @"</cards>"];
    
    NSLog(@"update: %@", string);
    [[ConnectionController sharedConnectionController]
     updateLesson: [[PreferencesController sharedPreferencesController] mainLessonName]
     withStringData: string
     andNotify: self];
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
    if (cardSet)
	[cardSet autorelease];
    cardSet = [cs retain];
    [self updateStats];
}

/*
 * Update the card set and save it.
 */
- (void) updateWithXMLParserDelegate: (XMLParserDelegate*) delegate
{
    PreferencesController *prefs = [PreferencesController sharedPreferencesController];

    [cardSet updateWithDeletedCardSet: [delegate deletedCardSet]
			      cardSet: [delegate cardSet]];
    [cardSet save];
    [prefs setVersion: [[delegate cardSet] version] ofLesson: [prefs mainLessonName]];
    [self updateStats];
}

/*
 * First the update finishes.  We set the card not changed and start
 * downloading the diff to the newest version.
 */
- (void) updateFinishedWithData: (NSData*) updateData
{
    NSArray *changed = [cardSet changedCards];
    NSEnumerator *enumerator;
    Card *card;
    
    enumerator = [changed objectEnumerator];
    while (card = [enumerator nextObject])
	[card setNotChanged];
    
    NSLog(@"Update finished");
    
    [[ConnectionController sharedConnectionController] 
     startDownloadLesson: [[PreferencesController sharedPreferencesController] mainLessonName]
     fromVersion: 0
     andNotify: self];
}

- (void) updateFailed
{
    NSLog(@"Update failed");
    [self enableAllButtons];
}

/*
 * The diff download finished.  Parse it and update the card set.
 */
- (void) downloadFinishedWithData: (NSData*) downloadData
{
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData: downloadData] autorelease];
    NSString *lessonName = [[PreferencesController sharedPreferencesController] mainLessonName];
    XMLParserDelegate *delegate = [[[XMLParserDelegate alloc] initWithLessonName: lessonName] autorelease];

    NSLog(@"Download data is %@", [[[NSString alloc] initWithData: downloadData encoding: NSUTF8StringEncoding] autorelease]);
    
    [parser setDelegate: delegate];
    [parser setShouldProcessNamespaces: NO];
    [parser setShouldReportNamespacePrefixes: NO];
    [parser setShouldResolveExternalEntities: NO];

    [parser parse];

    NSError *parseError = [parser parserError];
    if (parseError) {
	NSLog (@"XML parse error: %@", [parseError localizedDescription]);
    } else {
	NSLog (@"Parsed XML");
	[self updateWithXMLParserDelegate: delegate];
    }

    [self enableAllButtons];
}

/*
 * The download failed.  We need to save the card set because we have
 * done the update which might have changed the card set.
 */
- (void) downloadFailed
{
    NSLog(@"Download failed");
    [cardSet save];
    [self enableAllButtons];
}

@end
