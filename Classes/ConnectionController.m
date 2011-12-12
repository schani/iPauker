//
//  ConnectionController.m
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSStringAdditions.h"
#import "XMLParserDelegate.h"
#import "PreferencesController.h"

#import "ConnectionController.h"

//#define LOCAL_APPENGINE

#ifdef LOCAL_APPENGINE
#define URLBASE	"http://0.0.0.0:3000/ipauker"
#define EMAIL	"test@example.com"
#else
#define URLBASE "http://ipauker.appspot.com"
#endif

enum {
    StateInit,
    StateClientLogin,
    StateClientLoggedIn,
    StateLogin,
    StateLoggedIn,
    StateList,
    StateUpdate
};

static ConnectionController *connectionController;

@implementation ConnectionController

+ (ConnectionController*) sharedConnectionController
{
    if (!connectionController)
	connectionController = [[ConnectionController alloc] init];
    return connectionController;
}

- (id) init
{
    self = [super init];

    state = StateInit;

    return self;
}

- (void) dealloc
{
    [downloadData release];

    [super dealloc];
}

- (NSMutableURLRequest*) makeRequestForURL: (NSURL*) url withStringData: (NSString*) string
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
							   cachePolicy: NSURLRequestUseProtocolCachePolicy
						       timeoutInterval: 60.0];
    
    [request setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod: @"POST"];
    
    NSLog(@"making request for url %@ with data %@", url, string);

    if (string) {
	NSData *data = [string dataUsingEncoding: NSISOLatin1StringEncoding];
	[request setHTTPBody: data];
    }

    return request;
}

- (NSURLConnection*) makeConnectionForURL: (NSURL*) url withStringData: (NSString*) string
{
    NSMutableURLRequest *request = [self makeRequestForURL: url withStringData: string];
    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest: request delegate: self] autorelease];
    
    if (!connection) {
	NSLog (@"Cannot create connection object");
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    }
    
    return connection;
}

- (NSURLConnection*) makeConnectionForPath: (NSString*) path withStringData: (NSString*) string
{
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"%s/%@", URLBASE, path]];
    return [self makeConnectionForURL: url withStringData: string];
}

- (void) clientLogin
{
    PreferencesController *pref = [PreferencesController sharedPreferencesController];

    if (state == StateLoggedIn)
	return;

    NSAssert(state == StateInit, @"Wrong state");

#ifdef LOCAL_APPENGINE
    state = StateLoggedIn;
    [self processQueue];
#else
    NSAssert (downloadData == nil, @"Should be nil");
    downloadData = [[NSMutableData data] retain];

    [[self makeConnectionForURL: [NSURL URLWithString: @"https://www.google.com/accounts/ClientLogin"]
		 withStringData: [NSString stringWithFormat: @"Email=%@&Passwd=%@&accountType=GOOGLE&service=ah&source=iPauker",
					   [pref userName], [pref password]]]
	retain];
    state = StateClientLogin;
#endif
}

#ifndef LOCAL_APPENGINE
- (BOOL) extractAuthFromData: (NSData*) data
{
    NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    NSArray *lines = [string componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];

    NSAssert (auth == nil, @"Should not have auth");

    NSLog (@"extracting from %d bytes", [data length]);
    if (!string)
	NSLog (@"c string is %s", [data bytes]);

    for (NSString *line in lines) {
	NSArray *fields = [line componentsSeparatedByString: @"="];
	NSLog (@"line is %@ - has %d fields", line, [fields count]);
	if ([fields count] == 2 && [[fields objectAtIndex: 0] isEqualToString: @"Auth"]) {
	    auth = [[fields objectAtIndex: 1] retain];
	    return YES;
	}
    }
    return NO;
}

- (void) login
{
    NSAssert(state == StateClientLoggedIn, @"Wrong state");

#ifdef LOCAL_APPENGINE
    [[self makeConnectionForPath: @"_ah/login"
		  withStringData: [NSString stringWithFormat: @"email=%s&admin=False&action=Login", EMAIL]] retain];
#else
    NSAssert (auth, @"Must have auth to log in");
    [[self makeConnectionForPath: [NSString stringWithFormat: @"_ah/login?auth=%@", auth]
		  withStringData: nil] retain];
#endif

    state = StateLogin;
}
#endif

- (void) processQueue
{
    NSAssert(state == StateLoggedIn, @"Wrong state");

    if (queuedPath == nil)
	return;

    client = queuedClient;
    state = queuedState;
    downloadData = [[NSMutableData data] retain];
    [[self makeConnectionForPath: queuedPath withStringData: queuedStringData] retain];
    
    [queuedPath release];
    queuedPath = nil;

    [queuedStringData release];
    queuedStringData = nil;

    queuedClient = nil;
}

- (void) queueConnectionWithPath: (NSString*) path
		      stringData: (NSString*) stringData
			  client: (id) qClient
			   state: (int) qState
{
    if (state == StateLoggedIn)
	NSAssert (queuedPath == nil, @"Have queued connection despite being logged in");
    else
	NSAssert (state == StateClientLogin || state == StateLogin, @"Queueing connection despite processing something else");
    
    queuedPath = [path retain];
    queuedStringData = [stringData retain];
    queuedClient = [qClient retain];
    queuedState = qState;
    
    if (state == StateLoggedIn)
	[self processQueue];
}

- (void) startDownloadLesson: (NSString*) name
		 fromVersion: (int) version
		   andNotify: (id <DownloadClient>) downloadClient
{
    [self clientLogin];
    [self queueConnectionWithPath: @"list"
		       stringData: [NSString stringWithFormat: @"lesson=%@&version=%d", [name URLEncode], version]
			   client: downloadClient
			    state: StateList];
}

- (void) updateLesson: (NSString*) name
       withStringData: (NSString*) string
	    andNotify: (id <UpdateClient>) updateClient
{
    [self clientLogin];
    [self queueConnectionWithPath: @"update"
		       stringData: [NSString stringWithFormat: @"lesson=%@&data=%@",
				    [name URLEncode], [string URLEncode]]
			   client: updateClient
			    state: StateUpdate];
}

- (void) connection: (NSURLConnection*) connection didReceiveResponse: (NSURLResponse*) response
{
    NSLog(@"Response %@", response);
    if (downloadData)
	[downloadData setLength: 0];
}

- (void)connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    NSLog(@"Received %d bytes", [data length]);
    if (downloadData)
	[downloadData appendData: data];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    NSLog(@"Finished loading");
    [connection release];

    if (state == StateClientLogin) {
#ifdef LOCAL_APPENGINE
	NSAssert (NO, @"Should not be in client login state");
#else
	BOOL result = [self extractAuthFromData: [downloadData autorelease]];
	NSAssert (result, @"FIXME: Should handle error");
	downloadData = nil;
	state = StateClientLoggedIn;
	[self login];
#endif
    } else if (state == StateLogin) {
#ifdef LOCAL_APPENGINE
        NSAssert (NO, @"Should not be in login state");
#else
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
	    NSLog(@"cookie %@ - %@\n", [cookie name], [cookie value]);
	}
	state = StateLoggedIn;
	[self processQueue];
#endif
    } else if (state == StateList) {
	NSData *data = [downloadData autorelease];
	id cl = [client autorelease];
	client = nil;
	downloadData = nil;
	state = StateLoggedIn;
	[cl downloadFinishedWithData: data];
    } else if (state == StateUpdate) {
	NSData *data = [downloadData autorelease];
	id cl = [client autorelease];
	client = nil;
	downloadData = nil;
	state = StateLoggedIn;
	[cl updateFinishedWithData: data];
    }
}

- (void) connection: (NSURLConnection*) connection didFinishWithError: (NSError*) error
{
    NSLog(@"Connection failed! Error - %@ %@",
	  [error localizedDescription],
	  [[error userInfo] objectForKey: NSURLErrorFailingURLStringErrorKey]);

    if (state == StateLogin || state == StateList)
	[client downloadFailed];
    [connection release];
    if (state == StateLogin)
	state = StateInit;
    else
	state = StateLoggedIn;
    client = nil;
}

@end
