//
//  PreferencesController.h
//  iPauker
//
//  Created by Mark Probst on 10/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PreferencesController : NSObject {
    NSString *fileName;
    NSMutableDictionary *dict;
}

+ (PreferencesController*) sharedPreferencesController;

- (NSString*) userName;
- (void) setUserName: (NSString*) name;
- (NSString*) password;
- (void) setPassword: (NSString*) passwd;
- (NSString*) mainLessonName;
- (void) setMainLessonName: (NSString*) name;

- (int) versionOfLesson: (NSString*) lesson;
- (void) setVersion: (int) version ofLesson: (NSString*) lesson;

- (long long) ultraShortTermMemoryDuration;
- (long long) shortTermMemoryDuration;

@end
