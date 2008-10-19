//
//  CardSet.h
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"

@class Card;

@interface CardSet : NSObject {
    BOOL isFlipped;
    NSMutableArray *cards;
    
    BOOL countsCurrent;
    int numLearnedCards;
    int numExpiredCards;
    int numNewCards;
}

- (id) init;

- (void) addCard: (Card*) card;

- (int) numTotalCards;
- (int) numLearnedCards;
- (int) numExpiredCards;
- (int) numNewCards;

- (BOOL) isFlipped;

- (NSArray*) newCards;
- (NSArray*) expiredCards;
- (NSArray*) changedCards;

- (void) cardsMoved;

@end
