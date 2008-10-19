//
//  CardProcessing.m
//  iPauker
//
//  Created by Mark Probst on 8/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CardProcessing.h"

@implementation CardProcessing

- (id) initWithController: (iPaukerLearnViewController*) c
{
    self = [super init];
    
    controller = c;
    started = NO;
    
    return self;
}

- (void) start
{
    started = YES;
}

@end
