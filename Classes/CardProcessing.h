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

- (id) initWithController: (iPaukerLearnViewController*) c;

- (void) start;

- (void) next;

- (void) correct;
- (void) incorrect;

@end
