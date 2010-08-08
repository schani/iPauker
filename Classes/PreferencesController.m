//
//  PreferencesController.m
//  iPauker
//
//  Created by Mark Probst on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"


@implementation PreferencesController

+ (PreferencesController*) sharedPreferencesController
{
    static PreferencesController *controller;
    
    if (!controller)
	controller = [[PreferencesController alloc] init];
    
    return controller;
}
    
- (id) init
{
    self = [super init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    fileName = [[documentsDirectory stringByAppendingPathComponent: @"ipauker.plist"] retain];
    
    NSData *data = [NSData dataWithContentsOfFile: fileName];
    dict = (NSMutableDictionary*)[[NSPropertyListSerialization 
				   propertyListFromData: data
				   mutabilityOption: NSPropertyListMutableContainers
				   format: NULL
				   errorDescription: NULL] retain];

    return self;
}

- (NSMutableDictionary*) dict
{
    if (!dict)
	dict = [[NSMutableDictionary dictionary] retain];

    return dict;
}

- (void) writeData
{
    NSData *data = [NSPropertyListSerialization dataFromPropertyList: [self dict]
							      format: NSPropertyListXMLFormat_v1_0
						    errorDescription: NULL];

    if(data)
	[data writeToFile: fileName atomically: YES];
    else
	NSLog(@"Could not write preferences to %@", fileName);
}

static NSMutableDictionary*
force_dict (NSMutableDictionary *dict, NSString *key)
{
    NSMutableDictionary *d;

    d = [dict valueForKey: key];
    if (!d) {
	d = [NSMutableDictionary dictionary];
	[dict setValue: d forKey: key];
    }

    return d;
}

- (NSString*) userName
{
    return [[self dict] valueForKey: @"userName"];
}

- (void) setUserName: (NSString*) name
{
    [[self dict] setValue: name forKey: @"userName"];
}

- (NSString*) password
{
    return [[self dict] valueForKey: @"password"];
}

- (void) setPassword: (NSString*) passwd
{
    [[self dict] setValue: passwd forKey: @"password"];
}

- (NSString*) mainLessonName
{
    return [[self dict] valueForKey: @"mainLessonName"];
}

- (void) setMainLessonName: (NSString*) name
{
    [[self dict] setValue: name forKey: @"mainLessonName"];
}

- (int) versionOfLesson: (NSString*) lesson
{
    return [[[[[self dict] valueForKey: @"lessons"] valueForKey: lesson] valueForKey: @"version"] integerValue];
}

- (void) setVersion: (int) version ofLesson: (NSString*) lesson
{
    NSMutableDictionary *d;

    d = force_dict([self dict], @"lessons");
    d = force_dict(d, lesson);

    [d setValue: [NSNumber numberWithInt: version] forKey: @"version"];

    [self writeData];
}

- (long long) ultraShortTermMemoryDuration
{
    return 18 * 1000;
}

- (long long) shortTermMemoryDuration
{
    return 12 * 60 * 1000;
}

@end
