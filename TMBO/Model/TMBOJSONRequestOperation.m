//
//  TMBOJSONRequestOperation.m
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TMBOJSONRequestOperation.h"

#import "ISO8601DateFormatter.h"

@interface TMBOJSONRequestOperation ()
// THIS CLASS IS NOT THREAD SAFE!
@property (nonatomic, weak) NSString *currentKey;
- (id)parseItem:(id)item;
@end

@implementation TMBOJSONRequestOperation
@synthesize currentKey;

/*
 * responseJSON returns the parsed JSON data as Foundation objects, but when piping the result directly into a Core Data model, the types are occasionally incorrect. This causes really bad errors later, so inspect the result and ensure that data objects are of the correct types.
 */
- (id)responseJSON;
{
    return [self parseItem:[super responseJSON]];
}

- (id)parseItem:(id)item;
{
    if ([item isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)item;
        NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[array count]];
        for(id i in array) {
            self.currentKey = nil;
            [result addObject:[self parseItem:i]];
        }
        return result;
    } else if ([item isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)item;
        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[dictionary count]];
        for (id key in dictionary) {
            if ([key isKindOfClass:[NSString class]]) {
                self.currentKey = key;
            }
            id i = [dictionary objectForKey:key];
            [result setObject:[self parseItem:i] forKey:key];
        }
        self.currentKey = nil;
        return result;
    } else if ([item isKindOfClass:[NSString class]]) {
        if (currentKey) {
            // Avoid casting strings that might not actually be timestamps, by hardcoding the key
            if ([currentKey isEqualToString:@"timestamp"]
            || [currentKey isEqualToString:@"last_active"]) {
                NSTimeZone *tzone;
                [NSTimeZone setDefaultTimeZone:kServerTimeZone];
                NSDate *date = [[[ISO8601DateFormatter alloc] init] dateFromString:item timeZone:&tzone];
                if ([date compare:kDawnOfTime] == NSOrderedAscending) {
                    NSLog(@"Parsed key %@ (%@) as date, got %@", self.currentKey, item, date);
                    NotTested();
                    return item;
                }
                if (tzone) {
                    NSLog(@"Time zone info extracted from time: %@", tzone);
                    NotTested();
                }
                return date;
            }
        }
    } else if ([item isKindOfClass:[NSNumber class]]) {
        
    } else {
        NSLog(@"Item with key: %@ is of type: %@", self.currentKey, [item class]);
    }
    
    return item;
}

@end
