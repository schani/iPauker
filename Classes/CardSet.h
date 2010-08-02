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
    NSString *name;
    int version;
    
    BOOL isFlipped;
    NSMutableArray *cards;
    
    BOOL countsCurrent;
    int numLearnedCards;
    int numExpiredCards;
    int numNewCards;
    
    int highestKey;
    
    NSMutableSet *addedCards;
    NSMutableSet *dirtyCards;
    NSMutableSet *deletedCards;
}

- (id) initWithName: (NSString*) cardSetName;

- (int) version;
- (void) setVersion: (int) newVersion;

- (void) addCard: (Card*) card dirty: (BOOL) dirty;
- (void) setCardDirty: (Card*) card;

- (void) updateWithDeletedCardSet: (CardSet*) dcs cardSet: (CardSet*) cs;

- (int) numTotalCards;
- (int) numLearnedCards;
- (int) numExpiredCards;
- (int) numNewCards;

- (BOOL) isFlipped;

- (NSArray*) newCards;
- (NSArray*) expiredCards;
- (NSArray*) changedCards;

- (void) cardsMoved;

- (int) newKey;

- (void) save;

@end
