//
//  CardProcessing.h
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iPaukerLearnViewController.h"

@class iPaukerLearnViewController;

@interface CardProcessing : NSObject {
    iPaukerLearnViewController *controller;
    BOOL started;
}

+ (id) cardProcessingWithController: (iPaukerLearnViewController*) c
                              state: (NSDictionary*) state;

- (id) initWithController: (iPaukerLearnViewController*) c;
- (id) initWithController: (iPaukerLearnViewController*) c
                    state: (NSDictionary*) state;

- (void) start;

- (void) next;

- (void) correct;
- (void) incorrect;

- (NSDictionary*) state;

- (BOOL) hasTime;

- (void) updateTimeWithState: (NSDictionary*) state;

- (int) time;
- (int) subTime;

@end
