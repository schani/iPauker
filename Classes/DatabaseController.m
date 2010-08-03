//
//  DatabaseController.m
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DatabaseController.h"

static sqlite3_stmt *insert_stmt = NULL;
static sqlite3_stmt *update_stmt = NULL;
static sqlite3_stmt *delete_stmt = NULL;

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
	    Card *card = [[[Card alloc] initWithFrontText: [NSString stringWithCString: (char*)sqlite3_column_text(statement, 2)
									      encoding: NSUTF8StringEncoding]
					       frontBatch: sqlite3_column_int(statement, 3)
					   frontTimestamp: sqlite3_column_int64(statement, 4)
					      reverseText: [NSString stringWithCString: (char*)sqlite3_column_text(statement, 5)
									      encoding: NSUTF8StringEncoding]
					     reverseBatch: sqlite3_column_int(statement, 6)
					 reverseTimestamp: sqlite3_column_int64(statement, 7)
						      key: sqlite3_column_int(statement, 0)] autorelease];
	    
	    [cardSet addCard: card dirty: NO];
	    if (sqlite3_column_int (statement, 8))
		[card setChanged];
	}
    }
    
    sqlite3_free(sql);
    sqlite3_finalize(statement);
    
    return cardSet;
}

- (void) insertCards: (NSSet*) set forLesson: (NSString*) lesson
{
    NSEnumerator *enumerator;
    Card *card;

    if (insert_stmt == NULL) {
	char *sql = "INSERT INTO cards (key, lesson, front_text, front_batch, front_timestamp, " \
				       "reverse_text, reverse_batch, reverse_timestamp, changed) " \
			   "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
	
	if (sqlite3_prepare_v2(database, sql, -1, &insert_stmt, NULL) != SQLITE_OK)
	    NSAssert(NO, @"Could not prepare SQL statement");
    }
    
    enumerator = [set objectEnumerator];
    while (card = [enumerator nextObject]) {
	sqlite3_bind_int(insert_stmt, 1, [card key]);
	sqlite3_bind_text(insert_stmt, 2, [lesson UTF8String], -1, SQLITE_TRANSIENT);

	sqlite3_bind_text(insert_stmt, 3, [[[card frontSide] text] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(insert_stmt, 4, [[card frontSide] batch]);
	sqlite3_bind_int64(insert_stmt, 5, [[card frontSide] timestamp]);

	sqlite3_bind_text(insert_stmt, 6, [[[card reverseSide] text] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(insert_stmt, 7, [[card reverseSide] batch]);
	sqlite3_bind_int64(insert_stmt, 8, [[card reverseSide] timestamp]);

	sqlite3_bind_int(insert_stmt, 9, [card isChanged]);
	
	if (sqlite3_step(insert_stmt) == SQLITE_ERROR)
	    NSAssert1(NO, @"Could not insert row: %s", sqlite3_errmsg(database));
	
	sqlite3_reset(insert_stmt);
    }
}

- (void) updateCards: (NSSet*) cards forLesson: (NSString*) lesson
{
    NSEnumerator *enumerator;
    Card *card;
    
    if (update_stmt == NULL) {
	char *sql = "UPDATE cards SET front_batch=?, front_timestamp=?, " \
				     "reverse_batch=?, reverse_timestamp=?, changed=? " \
	                         "WHERE key=?";
	
	if (sqlite3_prepare_v2(database, sql, -1, &update_stmt, NULL) != SQLITE_OK)
	    NSAssert(NO, @"Could not prepare SQL statement");
    }
    
    enumerator = [cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	sqlite3_bind_int(update_stmt, 1, [[card frontSide] batch]);
	sqlite3_bind_int64(update_stmt, 2, [[card frontSide] timestamp]);

	sqlite3_bind_int(update_stmt, 3, [[card reverseSide] batch]);
	sqlite3_bind_int64(update_stmt, 4, [[card reverseSide] timestamp]);

	sqlite3_bind_int(update_stmt, 5, [card isChanged]);

	sqlite3_bind_int(update_stmt, 6, [card key]);

	if (sqlite3_step(update_stmt) == SQLITE_ERROR)
	    NSAssert1(NO, @"Could not insert row: %s", sqlite3_errmsg(database));

	sqlite3_reset(update_stmt);
    }
}

- (void) deleteCards: (NSSet*) cards forLesson: (NSString*) lesson
{
    NSEnumerator *enumerator;
    Card *card;

    if (delete_stmt == NULL) {
	char *sql = "DELETE FROM cards WHERE key=?";

	if (sqlite3_prepare_v2(database, sql, -1, &delete_stmt, NULL) != SQLITE_OK)
	    NSAssert (NO, @"Could not prepare SQL statement");
    }

    enumerator = [cards objectEnumerator];
    while (card = [enumerator nextObject]) {
	sqlite3_bind_int (delete_stmt, 1, [card key]);

	if (sqlite3_step (delete_stmt) == SQLITE_ERROR)
	    NSAssert1(NO, @"Could not delete row: %s", sqlite3_errmsg (database));

	sqlite3_reset (delete_stmt);
    }
}

@end
