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

    fileName = [documentsDirectory stringByAppendingPathComponent: @"ipauker.plist"];
    
    NSData *data = [NSData dataWithContentsOfFile: fileName];
    dict = (NSMutableDictionary*)[[NSPropertyListSerialization 
				   propertyListFromData: data
				   mutabilityOption: NSPropertyListMutableContainers
				   format: NULL
				   errorDescription: NULL] retain];

    return self;
}

- (void) writeData
{
    NSData *data = [NSPropertyListSerialization dataFromPropertyList: dict
							      format: NSPropertyListXMLFormat_v1_0
						    errorDescription: NULL];

    if(data)
	[data writeToFile: fileName atomically: YES];
    else
	NSLog(@"Could not write preferences to %@", fileName);
}

- (NSString*) mainLessonName
{
    return @"bla";
}

- (int) versionOfLesson: (NSString*) lesson
{
    return [[[[dict valueForKey: @"lessons"] valueForKey: lesson] valueForKey: @"version"] integerValue];
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

- (void) setVersion: (int) version ofLesson: (NSString*) lesson
{
    NSMutableDictionary *d;
    
    if (!dict)
	dict = [[NSMutableDictionary dictionary] retain];

    d = force_dict(dict, @"lessons");
    d = force_dict(d, lesson);

    [d setValue: [NSNumber numberWithInt: version] forKey: @"version"];

    [self writeData];
}

@end
