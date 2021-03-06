//
//  ObjectMapperInfo.h
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

#import <Foundation/Foundation.h>
#import "NSObject+ObjectMapper.h"

/**
 *  Definition of a block that is called when a data transformer is set.
 *  This block is used for both converting dictionary to model object and reverse
 *
 *  @param currentNode Current node to be converted
 *  @param parentNode  Parent Node
 *
 *  @return id
 */
typedef id (^MappingTransformer)(id currentNode, id parentNode);

@interface ObjectMappingInfo : NSObject

@property (nonatomic, copy) NSString *dictionaryKey;
@property (nonatomic, copy) NSString *propertyKey;
@property (nonatomic, copy) MappingTransformer transformer;
@property (nonatomic, assign) Class objectType;

- (instancetype)initWithDictionaryKey:(NSString *)aDictionaryKey
                          propertyKey:(NSString *)aPropertyKey
                        andObjectType:(Class)anObjectType NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDictionaryKey:(NSString *)aDictionaryKey
                          propertyKey:(NSString *)aPropertyKey
                       andTransformer:(MappingTransformer)transformer NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (NSString *)oc_javaClassNameKey;
+ (NSString *)oc_internalClassPreffixKey;
+ (NSString *)oc_internalClassSuffixKey;

+ (NSString *)oc_javaLongNumberNameKey;

+ (NSString *)oc_javaArrayNameKey;
+ (NSString *)oc_javaHashSetNameKey;
+ (NSString *)oc_javaHashMapNameKey;
+ (NSString *)oc_javaTreeMapNameKey;
+ (NSString *)oc_javaDateNameKey;
+ (NSString *)oc_javaMathTimestampNameKey;
+ (NSString *)oc_javaSQLTimestampNameKey;

+ (NSString *)oc_enumsPermissionNameKey;
+ (NSString *)oc_enumsStationOperationNameKey;
+ (NSString *)oc_enumsStationErrorCodeKey;

+ (NSString *)oc_configurationMapNameKey;
@end
