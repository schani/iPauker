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

@end
