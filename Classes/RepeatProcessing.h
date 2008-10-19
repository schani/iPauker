//
//  RepeatProcessing.h
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardProcessing.h"

@interface RepeatProcessing : CardProcessing {
    NSArray *cards;
    int index;
}

- (id) initWithController: (iPaukerLearnViewController*) c cards: (NSArray*) cs;

- (void) nextCard;

@end
