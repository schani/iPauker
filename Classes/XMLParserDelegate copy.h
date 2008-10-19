//
//  XMLParserDelegate.h
//  iPauker
//
//  Created by Mark Probst on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardSet.h"

@interface XMLParserDelegate : NSObject {
    CardSet *cardSet;
    int currentBatch;
    NSMutableString *frontSide;
    NSMutableString *backSide;
    int state;
}

- (id) init;

- (CardSet*) cardSet;

@end
