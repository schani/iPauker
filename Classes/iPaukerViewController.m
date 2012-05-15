#import "ConnectionController.h"
#import "XMLParserDelegate.h"
#import "DatabaseController.h"
#import "PreferencesController.h"

#import "iPaukerViewController.h"

@implementation iPaukerViewController

- (void) viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (applicationDidBecomeActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
}

- (void) viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) viewWillAppear: (BOOL) animated
{
    NSLog (@"main view will appear");

    [super viewWillAppear: animated];

    if (cardSet)
	[self updateStats];
}

- (void) viewDidAppear: (BOOL) animated
{
    if (![iPaukerLearnViewController hasSavedState])
        return;

    [self loadLearnViewController];
    [learnViewController restoreFromSavedStateWithCardSet: cardSet];
    [self presentModalViewController: learnViewController animated: NO];
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

- (void) loadPreferencesViewController
{
    if (!preferencesViewController) {
	preferencesViewController = [[iPaukerPreferencesViewController alloc] initWithNibName: @"iPaukerPreferencesView"
										       bundle: nil];
	[preferencesViewController setIPaukerViewController: self];
    }
}

- (void) loadLesson
{
    PreferencesController *pref = [PreferencesController sharedPreferencesController];
    NSString *name = [pref mainLessonName];
    NSLog (@"loading lesson %@", name);
    [self setCardSet: [[DatabaseController sharedDatabaseController] loadLesson: name]];
}

- (IBAction) settings: (id) sender
{
    [self loadPreferencesViewController];
    [self presentModalViewController: preferencesViewController animated: TRUE];
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
    PreferencesController *pref = [PreferencesController sharedPreferencesController];
    NSArray *changed = [cardSet changedCards];
    NSMutableString *string = [NSMutableString string];
    NSEnumerator *enumerator;
    Card *card;

    NSLog(@"version is %d", [pref versionOfLesson: [pref mainLessonName]]);

    [self disableAllButtons];
    
    [string appendString: @"<cards format=\"0.1\">\n"];
    enumerator = [changed objectEnumerator];
    while (card = [enumerator nextObject])
	[card writeXMLToString: string];
    [string appendString: @"</cards>"];
    
    NSLog(@"update: %@", string);
    [[ConnectionController sharedConnectionController]
     updateLesson: [pref mainLessonName]
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
    NSLog (@"%d cards in set", [cardSet numTotalCards]);
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
    PreferencesController *pref = [PreferencesController sharedPreferencesController];

    [cardSet updateWithDeletedCardSet: [delegate deletedCardSet]
			      cardSet: [delegate cardSet]];
    [cardSet save];
    [pref setVersion: [[delegate cardSet] version] ofLesson: [pref mainLessonName]];
    [self updateStats];
}

/*
 * First the update finishes.  We set the card not changed and start
 * downloading the diff to the newest version.
 */
- (void) updateFinishedWithData: (NSData*) updateData
{
    NSArray *changed = [cardSet changedCards];
    PreferencesController *pref = [PreferencesController sharedPreferencesController];
    NSString *lesson = [pref mainLessonName];
    NSEnumerator *enumerator;
    Card *card;
    
    enumerator = [changed objectEnumerator];
    while (card = [enumerator nextObject])
	[card setNotChanged];
    
    NSLog(@"Update finished");

    [[ConnectionController sharedConnectionController]
	startDownloadLesson: lesson
		fromVersion: [pref versionOfLesson: lesson]
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

- (void) applicationDidBecomeActive: (NSNotification*) notification
{
    [self updateStats];
}

@end
