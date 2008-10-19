//
//  NSStringAdditions.m
//  iPauker
//
//  Created by Mark Probst on 10/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSStringAdditions.h"


@implementation NSString (Encodings)

- (NSString*) URLEncode
{
    return (NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self,
							      NULL, CFSTR("?=&+;"), kCFStringEncodingUTF8);
}

- (NSString*) XMLEncode
{
    NSMutableString *tmp = [NSMutableString stringWithString: self];
    CFStringTransform ((CFMutableStringRef)tmp, NULL, kCFStringTransformToXMLHex, NO);
    return tmp;
}

@end
