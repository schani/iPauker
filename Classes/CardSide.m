//
//  CardSide.m
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <math.h>

#import "CardSide.h"
#import "iPaukerAppDelegate.h"

@implementation CardSide

- (id) initForCard: (Card*) c withText: (NSString*) t batch: (int) b timestamp: (long long) ts
{
    self = [super init];
    
    card = c;
    
    text = [t retain];
    batch = b;
    timestamp = ts;

    return self;
}

- (void) dealloc
{
    [text release];
    
    [super dealloc];
}

- (NSString*) text
{
    return text;
}

- (int) batch
{
    return batch;
}

- (void) markChange
{
    [card setChangedAndDirty: YES];
    timestamp = [iPaukerAppDelegate updateAndGetTime];
    [[card cardSet] cardsMoved];
}

- (void) nextBatch
{
    NSAssert (![self isNew], @"Cannot increase batch of new card");

    ++batch;
    [self markChange];
}

- (BOOL) isNew
{
    return batch < 1;
}

- (void) setNew
{
    batch = -2;
    [self markChange];
}

- (void) setLearned
{
    NSAssert ([self isNew], @"Cannot set learned of card that is not new");

    batch = 1;
    [self markChange];
}

- (long long) timestamp
{
    return timestamp;
}

static long long
batch_expire_time (int batch)
{
    long long time = (long long) (3600 * 24 * exp (batch) * 1000);

    return time;
}

+ (long long) expireTimeForBatch: (int) batch
{
    static BOOL inited = NO;
    static long long times [8];
    
    if (batch < 1)
	return 0;
    
    --batch;
    
    if (batch >= 8)
	return batch_expire_time (batch);

    if (!inited) {
	int i;

	for (i = 0; i < 8; ++i)
	    times [i] = batch_expire_time (i);
	inited = YES;
    }
    
    return times [batch];
}

- (long long) expireTimestamp
{
    return timestamp + [CardSide expireTimeForBatch: batch];
}

- (BOOL) isExpired
{
    long long currentTime = [(iPaukerAppDelegate*)[[UIApplication sharedApplication] delegate] currentTime];
    long long expireTimestamp = [self expireTimestamp];

    return expireTimestamp < currentTime;
}

@end
