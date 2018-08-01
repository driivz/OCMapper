//
//  ObjectMapperInfo.m
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

#import "ObjectMappingInfo.h"

@implementation ObjectMappingInfo

#pragma mark - Initialization -

- (instancetype)initWithDictionaryKey:(NSString *)aDictionaryKey
                          propertyKey:(NSString *)aPropertyKey
                        andObjectType:(Class)anObjectType
{
    if (self = [super init])
    {
        self.dictionaryKey = aDictionaryKey;
        self.propertyKey = aPropertyKey;
        self.objectType = anObjectType;
    }
    
    return self;
}

- (instancetype)initWithDictionaryKey:(NSString *)aDictionaryKey
                          propertyKey:(NSString *)aPropertyKey
                       andTransformer:(MappingTransformer)transformer
{
    if (self = [super init])
    {
        self.dictionaryKey = aDictionaryKey;
        self.propertyKey = aPropertyKey;
        self.transformer = transformer;
    }
    
    return self;
}

+ (NSString *)oc_javaClassNameKey {
    return @"class";
}

+ (NSString *)oc_internalClassPreffixKey {
    return @"";
}

+ (NSString *)oc_internalClassSuffixKey {
    return @"";
}

+ (NSString *)oc_javaLongNumberNameKey {
    return @"java.lang.Long";
}

+ (NSString *)oc_javaArrayNameKey {
    return @"java.util.ArrayList";
}

+ (NSString *)oc_javaHashSetNameKey {
    return @"java.util.HashSet";
}

+ (NSString *)oc_javaHashMapNameKey {
    return @"java.util.HashMap";
}

+ (NSString *)oc_javaDateNameKey {
    return @"java.util.Date";
}

+ (NSString *)oc_javaMathTimestampNameKey {
    return @"java.math.Timestamp";
}

+ (NSString *)oc_javaSQLTimestampNameKey {
    return @"java.sql.Timestamp";
}

+ (NSString *)oc_enumsPermissionNameKey {
    return @"";
}

+ (NSString *)oc_enumsStationOperationNameKey {
    return @"";
}

+ (NSString *)oc_enumsStationErrorCodeKey {
    return @"";
}

+ (NSString *)oc_configurationMapNameKey {
    return @"";
}

@end
