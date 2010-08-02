//
//  LearnProcessing.h
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardProcessing.h"

enum {
    MODE_MEMORIZE,
    MODE_REPEAT_MEMORIZED,
    MODE_REPEAT_KNOWN
};

@interface LearnProcessing : CardProcessing{
    NSMutableArray *newCards;
    NSMutableArray *repeatCards;
    NSMutableArray *knownCards;
    int mode;
    long long startTime;
    long long memorizeStartTime;
}

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cards;

- (BOOL) isMemorizeExpired;
- (BOOL) isShortTermMemoryExpired;

- (void) setMemorizeMode;
- (void) setRepeatMemorizedMode;
- (void) setRepeatKnownMode;

@end
