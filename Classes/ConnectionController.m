//
//  ConnectionController.m
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSStringAdditions.h"
#import "XMLParserDelegate.h"

#import "ConnectionController.h"

enum {
    StateInit,
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

- (NSMutableURLRequest*) makeRequestForPath: (NSString*) path withStringData: (NSString*) string
{
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://192.168.1.130:8080/%@", path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
							   cachePolicy: NSURLRequestUseProtocolCachePolicy
						       timeoutInterval: 60.0];
    
    [request setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod: @"POST"];
    
    NSLog(@"making request for path %@ with data %@", path, string);
    
    NSData *data = [string dataUsingEncoding: NSISOLatin1StringEncoding];
    
    [request setHTTPBody: data];
    
    return request;
}

- (NSURLConnection*) makeConnectionForPath: (NSString*) path withStringData: (NSString*) string
{
    NSMutableURLRequest *request = [self makeRequestForPath: path withStringData: string];
    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest: request delegate: self] autorelease];
    
    if (!connection) {
	NSLog (@"Cannot create connection object");
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    }
    
    return connection;
}

- (void) login
{
    if (state == StateLoggedIn)
	return;
    NSAssert(state == StateInit, @"Wrong state");
    [[self makeConnectionForPath: @"_ah/login"
		  withStringData: @"email=test@example.com&admin=False&action=Login"] retain];
    state = StateLogin;
}

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
	NSAssert (state == StateLogin, @"Queueing connection despite processing something else");
    
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
    [self login];
    [self queueConnectionWithPath: @"list"
		       stringData: [NSString stringWithFormat: @"lesson=%@&version=%d", [name URLEncode], version]
			   client: downloadClient
			    state: StateList];
}

- (void) updateLesson: (NSString*) name
       withStringData: (NSString*) string
	    andNotify: (id <UpdateClient>) updateClient
{
    [self login];
    [self queueConnectionWithPath: @"update"
		       stringData: [NSString stringWithFormat: @"lesson=%@&data=%@",
				    [name URLEncode], [string URLEncode]]
			   client: updateClient
			    state: StateUpdate];
}

- (void) connection: (NSURLConnection*) connection didReceiveResponse: (NSURLResponse*) response
{
    NSLog(@"Response");
    if (downloadData)
	[downloadData setLength: 0];
}

- (void)connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    NSLog(@"Received");
    if (downloadData)
	[downloadData appendData: data];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    NSLog(@"Finished loading");
    [connection release];
    
    if (state == StateLogin) {
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
	    NSLog(@"cookie %@ - %@\n", [cookie name], [cookie value]);
	}
	state = StateLoggedIn;
	[self processQueue];
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
	  [[error userInfo] objectForKey: NSErrorFailingURLStringKey]);

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
