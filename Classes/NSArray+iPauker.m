//
//  NSArray+iPauker.m
//  iPauker
//
//  Created by Mark Probst on 5/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSArray+F.h"

#import "NSArray+iPauker.h"

@implementation NSArray (iPauker)

- (NSArray*) arrayWithCardKeys
{
    return [self map: ^ (Card *card) { return [NSNumber numberWithInt: [card key]]; }];
}

- (NSArray*) arrayWithCardsFromCardSet: (CardSet*) cs
{
    return [self map: ^ (NSNumber *key) { return [cs cardForKey: [key intValue]]; }];
}

@end
