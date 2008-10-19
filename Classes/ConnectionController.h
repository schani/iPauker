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


@interface ConnectionController : NSObject {
    int state;
    NSMutableData *downloadData;
    id client;
}

+ (ConnectionController*) sharedConnectionController;

- (id) init;

- (void) startDownloadAndNotify: (id <DownloadClient>) downloadClient;

- (void) updateLesson: (NSString*) name withStringData: (NSString*) string;

@end
