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
    int state;
    NSMutableString *text;

    int frontBatch;
    NSString *frontText;
    long long frontTimestamp;

    int reverseBatch;
    NSString *reverseText;
    long long reverseTimestamp;
}

- (id) init;

- (CardSet*) cardSet;

@end
