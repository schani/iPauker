//
//  Card.h
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardSet.h"
#import "CardSide.h"

@class CardSide;
@class CardSet;

@interface Card : NSObject {
    CardSet *cardSet;
    CardSide *frontSide;
    CardSide *reverseSide;
}

- (id) initWithFrontText: (NSString*) ft
	      frontBatch: (int) fb
	  frontTimestamp: (long long) fts
	     reverseText: (NSString*) rt
	    reverseBatch: (int) rb
	reverseTimestamp: (long long) rts;

- (void) setCardSet: (CardSet*) cs;
- (CardSet*) cardSet;

- (CardSide*) questionSide;
- (CardSide*) answerSide;

- (NSString*) question;
- (NSString*) answer;

- (BOOL) isChanged;

@end
