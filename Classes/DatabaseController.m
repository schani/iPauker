//
//  DatabaseController.m
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DatabaseController.h"

@implementation DatabaseController

+ (DatabaseController*) sharedDatabaseController
{
    static DatabaseController *controller;
    
    if (!controller)
	controller = [[DatabaseController alloc] init];
    
    return controller;
}

- (id) init
{
    self = [super init];

    database = NULL;

    return self;
}

- (NSString*) databaseFileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    return [documentsDirectory stringByAppendingPathComponent: @"ipauker1.sql"];
}

- (void) createTables
{
    static const char *sql =
    "CREATE TABLE IF NOT EXISTS cards (" \
    "key INTEGER PRIMARY KEY," \
    "lesson TEXT NOT NULL," \
    "front_text TEXT NOT NULL," \
    "front_batch INTEGER NOT NULL," \
    "front_timestamp INTEGER NOT NULL," \
    "reverse_text TEXT NOT NULL," \
    "reverse_batch TEXT NOT NULL," \
    "reverse_timestamp INTEGER NOT NULL," \
    "changed INTEGER NOT NULL" \
    ")";

    if (sqlite3_exec(database, sql, NULL, 0, NULL) != SQLITE_OK) {
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    }
}

- (void) openDatabase
{
    NSString *fileName;
    
    if (database)
	return;

    fileName = [self databaseFileName];
    NSLog(@"filename is %@", fileName);
    
    if (sqlite3_open([fileName UTF8String], &database) != SQLITE_OK) {
	NSLog(@"cannot open database");
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    }
    
    [self createTables];
}

- (CardSet*) loadLesson: (NSString*) lesson
{
    static const char *sql_format = "SELECT * FROM cards WHERE lesson = '%q'";
    
    char *sql = sqlite3_mprintf(sql_format, [lesson UTF8String]);
    sqlite3_stmt *statement;
    
    CardSet *cardSet = [[[CardSet alloc] initWithName: lesson] autorelease];
    
    [self openDatabase];
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
	while (sqlite3_step(statement) == SQLITE_ROW) {
	    Card *card = [[[Card alloc] initWithFrontText: [NSString stringWithCString: (char*)sqlite3_column_text(statement, 2)]
					       frontBatch: sqlite3_column_int(statement, 3)
					   frontTimestamp: sqlite3_column_int64(statement, 4)
					      reverseText: [NSString stringWithCString: (char*)sqlite3_column_text(statement, 5)]
					     reverseBatch: sqlite3_column_int(statement, 6)
					 reverseTimestamp: sqlite3_column_int64(statement, 7)
						      key: sqlite3_column_int(statement, 0)] autorelease];
	    
	    [cardSet addCard: card];
	}
    }
    
    sqlite3_free(sql);
    sqlite3_finalize(statement);
    
    return cardSet;
}

@end
