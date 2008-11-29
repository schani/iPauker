//
//  ConnectionController.h
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DownloadClient

- (void) downloadFinishedWithData: (NSData*) downloadData;
- (void) downloadFailed;

@end

@protocol UpdateClient

- (void) updateFinishedWithData: (NSData*) updateData;
- (void) updateFailed;

@end

@interface ConnectionController : NSObject {
    int state;
    NSMutableData *downloadData;
    id client;
    
    NSString *queuedPath;
    NSString *queuedStringData;
    id queuedClient;
    int queuedState;
}

+ (ConnectionController*) sharedConnectionController;

- (id) init;

- (void) startDownloadLesson: (NSString*) name
		 fromVersion: (int) version
		   andNotify: (id <DownloadClient>) downloadClient;

- (void) updateLesson: (NSString*) name
       withStringData: (NSString*) string
	    andNotify: (id <UpdateClient>) updateClient;

@end
