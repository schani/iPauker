//
//  NSArray+iPauker.h
//  iPauker
//
//  Created by Mark Probst on 5/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CardSet.h"

@interface NSArray (iPauker)

- (NSArray*) arrayWithCardKeys;
- (NSArray*) arrayWithCardsFromCardSet: (CardSet*) cs;

@end
