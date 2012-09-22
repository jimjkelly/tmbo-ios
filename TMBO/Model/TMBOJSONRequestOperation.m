//
//  TMBOJSONRequestOperation.m
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
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
                // TODO: do we need to save the device's current time zone?
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
