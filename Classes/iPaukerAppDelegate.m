//
//  iPaukerAppDelegate.m
//  iPauker
//
//  Created by Mark Probst on 8/12/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <sys/time.h>
#import <time.h>

#import "iPaukerAppDelegate.h"
#import "iPaukerViewController.h"
#import "XMLParserDelegate.h"

enum {
    StateLogin,
    StateList,
    StateDone
};

@implementation iPaukerAppDelegate

@synthesize window;
@synthesize viewController;

- (void) updateTime
{
    struct timezone tz;
    struct timeval tv;
    
    tz.tz_minuteswest = 0;
    tz.tz_dsttime = 0;
    
    gettimeofday (&tv, &tz);

    currentTime = (long long)tv.tv_sec * 1000 + (long long)tv.tv_usec / 1000;
    
    NSLog(@"update current time to %lld", currentTime);
}

- (long long) currentTime
{
    return currentTime;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Override point for customization after app launch	
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

    //[viewController setCardSet: cardSet];
    
    [self startDownload];
}

- (void)dealloc {
    [viewController release];
    [window release];
    [downloadData release];
    //[fileName release];
    [super dealloc];
}

- (NSMutableURLRequest*) makeRequestForPath: path withStringData: string
{
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://192.168.1.130:8080/%@", path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
							   cachePolicy: NSURLRequestUseProtocolCachePolicy
						       timeoutInterval: 60.0];

    [request setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod: @"POST"];

    NSData *data = [string dataUsingEncoding: NSISOLatin1StringEncoding];

    [request setHTTPBody: data];

    return request;
}

- (void)startDownload
{
    NSMutableURLRequest *request = [self makeRequestForPath: @"_ah/login"
					     withStringData: @"email=test@example.com&admin=False&action=Login"];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate: self];

    /*
    NSURLDownload *download = [[NSURLDownload alloc] initWithRequest: request delegate: self];
     */

    if (connection) {
	state = StateLogin;
	/*
	fileName = [[NSString pathWithComponents: [NSArray arrayWithObjects: NSTemporaryDirectory(), @"cards.xml", nil]] retain];
	[download setDestination: fileName allowOverwrite: YES];
	 */
    } else {
	NSLog (@"Cannot create download object");
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    }
}

- (void) connection: (NSURLConnection*) connection didReceiveResponse: (NSURLResponse*) response
{
    NSLog(@"Response");
    if (downloadData)
	[downloadData setLength: 0];
}

- (void)connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    if (downloadData)
	[downloadData appendData:data];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    NSLog(@"Finished loading");
    [connection release];

    if (state == StateLogin) {
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
	    NSLog(@"%@ - %@\n", [cookie name], [cookie value]);
	}

	NSMutableURLRequest *request = [self makeRequestForPath: @"list" withStringData: @"lesson=bla&version=0"];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate: self];

	if (connection) {
	    downloadData = [[NSMutableData data] retain];
	    state = StateList;
	} else {
	    NSLog (@"Cannot create download object");
	    CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
	}
    } else if (state == StateList) {
	[downloadData autorelease];
	
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
	
	[viewController setCardSet: [delegate cardSet]];
	
	downloadData = nil;
	state = StateDone;
    }
}

- (void) connection: (NSURLConnection*) connection didFinishWithError: (NSError*) error
{
    NSLog(@"Connection failed! Error - %@ %@",
	  [error localizedDescription],
	  [[error userInfo] objectForKey: NSErrorFailingURLStringKey]);
}

/*
- (void) download: (NSURLDownload*) download didFailWithError: (NSError*) error
{
    NSLog (@"Download failed: %@", [error localizedDescription]);
    CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

- (void) downloadDidFinish: (NSURLDownload*) download
{
    [download release];
    
    NSLog (@"Download finished to %@", fileName);
    
    NSData *data = [NSData dataWithContentsOfMappedFile: fileName];
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData: data] autorelease];
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
    
    [viewController setCardSet: [delegate cardSet]];
}
 */

@end
