//
//  XMLParserDelegate.h
//  iPauker
//
//  Created by Mark Probst on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardSet.h"

@interface XMLParserDelegate : NSObject <NSXMLParserDelegate> {
    CardSet *cardSet;
    CardSet *deletedCardSet;
    int state;
    NSMutableString *text;
    BOOL deleted;

    int frontBatch;
    NSString *frontText;
    long long frontTimestamp;

    int reverseBatch;
    NSString *reverseText;
    long long reverseTimestamp;
}

- (id) initWithLessonName: (NSString*) name;

- (CardSet*) cardSet;
- (CardSet*) deletedCardSet;

@end
