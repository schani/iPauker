//
//  DatabaseController.h
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#import "CardSet.h"

@interface DatabaseController : NSObject {
    sqlite3 *database;
}

+ (DatabaseController*) sharedDatabaseController;

- (CardSet*) loadLesson: (NSString*) lesson;

- (void) insertCards: (NSSet*) set forLesson: (NSString*) lesson;
- (void) updateCards: (NSSet*) cards forLesson: (NSString*) lesson;
- (void) deleteCards: (NSSet*) cards forLesson: (NSString*) lesson;

@end
