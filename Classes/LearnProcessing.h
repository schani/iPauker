//
//  LearnProcessing.h
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardProcessing.h"

@interface LearnProcessing : CardProcessing{
    NSMutableArray *newCards;
    NSMutableArray *repeatCards;
    NSMutableArray *knownCards;
    BOOL repeatingKnown;
}

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cards;

@end
