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
    [window addSubview: viewController.view];
    [window makeKeyAndVisible];

    //[viewController setCardSet: cardSet];
    
    [viewController startDownload];
}

- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}

@end
