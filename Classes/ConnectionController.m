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
    StateIdle,
    StateLogin,
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

    state = StateIdle;

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
    
    NSLog(@"making request with: %@", string);
    
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

- (void) startDownloadAndNotify: (id <DownloadClient>) downloadClient
{
    [[self makeConnectionForPath: @"_ah/login"
		  withStringData: @"email=test@example.com&admin=False&action=Login"] retain];
    client = downloadClient;
    state = StateLogin;
}

- (void) updateLesson: (NSString*) name withStringData: (NSString*) string
{
    [[self makeConnectionForPath: @"update"
		  withStringData: [NSString stringWithFormat: @"lesson=%@&data=%@",
				   [name URLEncode], [string URLEncode]]] retain];

    state = StateUpdate;
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
	[downloadData appendData: data];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    NSLog(@"Finished loading");
    [connection release];
    
    if (state == StateLogin) {
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
	    NSLog(@"%@ - %@\n", [cookie name], [cookie value]);
	}
	
	[[self makeConnectionForPath: @"list" withStringData: @"lesson=bla&version=0"] retain];
	downloadData = [[NSMutableData data] retain];
	state = StateList;
    } else if (state == StateList) {
	[client downloadFinishedWithData: downloadData];
	[downloadData release];
	downloadData = nil;
	state = StateIdle;
	client = nil;
    } else if (state == StateUpdate) {
	NSLog(@"Finished update");
	state = StateIdle;
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
    state = StateIdle;
    client = nil;
}

@end
