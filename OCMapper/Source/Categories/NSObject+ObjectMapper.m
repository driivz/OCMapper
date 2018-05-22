//
//  NSObject+ObjectMapper.m
//  OCMapper
//
//  Created by Aryan Gh on 4/14/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//
// https://github.com/aryaxt/OCMapper
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSObject+ObjectMapper.h"
#import "ObjectMappingInfo.h"

@implementation NSObject (ObjectMapper)

+ (instancetype)objectFromDictionary:(NSDictionary *)dictionary
{
    return [[ObjectMapper sharedInstance] objectFromSource:dictionary toInstanceOfClass:[self class]];
}

- (Class)internalClassName {
    NSString *serverClassName = self.description;
    NSString *className = [serverClassName copy];
    
    NSArray *components = [serverClassName componentsSeparatedByString:@"."];
    
    if (components.count > 1) {
        className = components.lastObject;
        className = [[ObjectMappingInfo oc_internalClassPreffixKey] stringByAppendingString:className];
        className = [className stringByReplacingOccurrencesOfString:[ObjectMappingInfo oc_internalClassSuffixKey] withString:@""];
    }
    
    Class _class = NSClassFromString(className);
    
    return _class;
}

+ (NSString *)javaClassName {
    return @"";
}

+ (id)jsonMappedObject {
    return nil;
}

+ (id)jsonMappedValue:(id)value {
    return value;
}

- (NSArray *)javaTimestamp {
    return @[];
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    NSString *javaClassName = [[self class] javaClassName];
    if (javaClassName.length)
    {
        properties[[ObjectMappingInfo oc_javaClassNameKey]] = javaClassName;
    }
    
    [properties addEntriesFromDictionary:[[ObjectMapper sharedInstance] dictionaryFromObject:self]];
    
    return properties;
}

- (NSDictionary *)dictionaryWrappedInParentWithKey:(NSString *)key
{
    return @{key: [self dictionary]};
}

- (NSDate *)javaTimestampToNSDate {
    id object = self;
    if ([object isKindOfClass:[NSNull class]] || object == nil) {
        return nil;
    }
    
    if ([object isKindOfClass:[NSArray class]]) {
        object = [object lastObject];
    }
    
    NSTimeInterval timestampSeconds = [object doubleValue] / 1000.0;
    return [NSDate dateWithTimeIntervalSince1970:timestampSeconds];
}

- (NSArray *)arrayToServer {
    return [[ObjectMapper sharedInstance] dictionaryFromObject:self];
}

@end
