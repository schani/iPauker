//
//  CardSide.h
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@class Card;

@interface CardSide : NSObject {
    Card *card;

    NSString *text;
    int batch;
    long long timestamp;
}

- (id) initForCard: (Card*) c withText: (NSString*) t batch: (int) b timestamp: (long long) ts;

- (NSString*) text;

- (int) batch;
- (void) nextBatch;

- (BOOL) isNew;
- (void) setNew;
- (void) setLearned;

- (long long) timestamp;

- (BOOL) isExpired;

@end
