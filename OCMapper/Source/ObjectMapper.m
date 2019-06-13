//
//  ObjectMapper.m
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

#import "ObjectMapper.h"
#import <objc/runtime.h>
#import "ObjectMappingInfo.h"
#import "InstanceProvider.h"
#import "MappingProvider.h"
#import "LoggingProvider.h"
#import "ObjectInstanceProvider.h"
#import "NSObject+ObjectMapper.h"
#import "OCBigDecimalNumber.h"

#ifdef DEBUG
#define ILog(format, ...) [self.loggingProvider log:[NSString stringWithFormat:(format), ##__VA_ARGS__] withLevel:LogLevelInfo]
#define WLog(format, ...) [self.loggingProvider log:[NSString stringWithFormat:(format), ##__VA_ARGS__] withLevel:LogLevelWarning]
#define ELog(format, ...) [self.loggingProvider log:[NSString stringWithFormat:(format), ##__VA_ARGS__] withLevel:LogLevelError]
#else
#define ILog(format, ...) /* */
#define WLog(format, ...) /* */
#define ELog(format, ...) /* */
#endif

@interface ObjectMapper()
@property (nonatomic, strong) NSMutableArray *commonDateFormaters;
@property (nonatomic, strong) NSMutableDictionary *mappedClassNames;
@property (nonatomic, strong) NSMutableDictionary *mappedPropertyNames;
@property (nonatomic, strong) ObjectInstanceProvider *instanceProvider;
@end

@implementation ObjectMapper

#pragma mark - initialization -

+ (ObjectMapper *)sharedInstance {
    static ObjectMapper *singleton;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[ObjectMapper alloc] init];
    });
    
    return singleton;
}

- (instancetype)init {
    if (self = [super init]) {
        self.instanceProvider = [[ObjectInstanceProvider alloc] init];
        
        self.mappedClassNames = [NSMutableDictionary new];
        self.mappedPropertyNames = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark - Public Methods -

- (id)objectFromSource:(id)source toInstanceOfClass:(Class)class {
    id object = nil;
    if ([source isKindOfClass:[NSDictionary class]]) {
        ILog(@"____________________ Mapping Dictionary to instance [%@] ____________________", NSStringFromClass(class));
        object = [self dr_processDictionary:source forClass:class];
    }
    else if ([source isKindOfClass:[NSArray class]]) {
        ILog(@"____________________   Mapping Array to instance [%@] ____________________", NSStringFromClass(class));
        object = [self processArray:source forClass:class];
    }
    else {
        ILog(@"____________________   Mapping field [%@] ____________________", NSStringFromClass(class));
        object = source;
    }
    
    return object;
}

- (id)dictionaryFromObject:(__kindof NSObject *)object {
    if ([object isKindOfClass:[NSArray class]]) {
        return [self dr_processDictionaryFromArray:object];
    }
    else {
        return [self processDictionaryFromObject:object];
    }
}

#pragma mark - Private Methods -

- (NSArray *)dr_processDictionaryFromArray:(NSArray *)array {
    NSObject *object = array.firstObject;
    if ([NSBundle mainBundle] != [NSBundle bundleForClass:object.class]) {
        // is CFTypes: NSString, NSnumber etc
        return @[[ObjectMappingInfo oc_javaArrayNameKey], array];
    }
    
    NSMutableArray *objects = [NSMutableArray array];
    for (id valueInArray in array) {
        NSMutableDictionary *dic = [self dictionaryFromObject:valueInArray];
        dic[[ObjectMappingInfo oc_javaClassNameKey]] = [[valueInArray class] javaClassName];
        [objects addObject:dic];
    }
    
    return @[[ObjectMappingInfo oc_javaArrayNameKey], [objects copy]];
}

- (NSArray *)processDictionaryFromArray:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    
    for (id valueInArray in array) {
        [result addObject:[self dictionaryFromObject:valueInArray]];
    }
    
    return result;
}

- (id)processDictionaryFromObject:(NSObject *)object {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    Class currentClass = [object class];
    
    while (currentClass && currentClass != [NSObject class]) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(currentClass, &outCount);
        NSArray *excludedKeys = [self.mappingProvider excludedKeysForClass:currentClass];
        
        for (i = 0; i < outCount; ++i)
        {
            objc_property_t property = properties[i];
            NSString *originalPropertyName = @(property_getName(property));
            
            if (excludedKeys && [excludedKeys containsObject:originalPropertyName]) {
                continue;
            }
            
            Class class = NSClassFromString([self typeForProperty:originalPropertyName andClass:[object class]]);
            id propertyValue = [object valueForKey:originalPropertyName];
            if (!propertyValue) {
                //skip if nothing
                continue;
            }
            
            ObjectMappingInfo *mapingInfo = [self.mappingProvider mappingInfoForClass:[object class] andPropertyKey:originalPropertyName];
            NSString *propertyName = (mapingInfo) ? mapingInfo.dictionaryKey : originalPropertyName;
            
            if (mapingInfo.transformer && propertyValue) {
                propertyValue = mapingInfo.transformer(propertyValue, object);
                props[propertyName] = propertyValue;
            }
            // If class is in the main bundle it's an application specific class
            else if (propertyValue && [NSBundle mainBundle] == [NSBundle bundleForClass:[propertyValue class]]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                dic[[ObjectMappingInfo oc_javaClassNameKey]] = [class javaClassName];
                
                [dic addEntriesFromDictionary:[self dictionaryFromObject:propertyValue]];
                
                props[propertyName] = dic;
            }
            // It's not in the main bundle so it's a Cocoa Class
            else {
                NSString *jsonMappedObject = [class jsonMappedObject];
                if (class == [NSDate class]) {
                    propertyValue = [propertyValue javaTimestamp];
                }
                else if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]]) {
                    propertyValue = [self dr_processDictionaryFromArray:propertyValue];
                }
                else if (jsonMappedObject) {
                    propertyValue = [class jsonMappedValue:propertyValue];
                }
                
                if (propertyValue) {
                    props[propertyName] = propertyValue;
                }
            }
        }
        
        free(properties);
        currentClass = class_getSuperclass(currentClass);
    }
    
    return props;
}

// Here we normalize dictionary made for flat-to-complex-object mapping
// For instance in a mapping from "city" to "address.city" we break down "address" and "city"
- (NSDictionary *)normalizedDictionaryFromDictionary:(NSDictionary *)source forClass:(Class)class {
    NSMutableDictionary *newDictionary = [source mutableCopy];
    [newDictionary removeObjectForKey:[ObjectMappingInfo oc_javaClassNameKey]];
    
    return newDictionary;
}

- (id)dr_processDictionary:(NSDictionary *)value forClass:(Class)class {
    
    id object = [self.instanceProvider emptyInstanceForClass:class];
    if ([object isKindOfClass:[NSDictionary class]]) {
        object = [object mutableCopy];
    }
    
    NSString *className = value[[ObjectMappingInfo oc_javaClassNameKey]];
    if ([className isEqualToString:[ObjectMappingInfo oc_javaHashMapNameKey]]
        || [className isEqualToString:[ObjectMappingInfo oc_javaTreeMapNameKey]]) {
        [value enumerateKeysAndObjectsUsingBlock:^(NSString *key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key rangeOfString:[NSString stringWithFormat:@"\"%@\"", [ObjectMappingInfo oc_javaClassNameKey]]].location != NSNotFound) {
                NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *keyObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSString *className = keyObject[[ObjectMappingInfo oc_javaClassNameKey]];
                key = [self objectFromSource:keyObject toInstanceOfClass:[className internalClassName]];
            }
            
            if (![[ObjectMappingInfo oc_javaClassNameKey] isEqualToString:key]) {
                if ([obj isKindOfClass:[NSArray class]]) {
                    object[key] = [self objectFromSource:obj toInstanceOfClass:[NSArray class]];
                }
                else {
                    NSString *className = obj[[ObjectMappingInfo oc_javaClassNameKey]];
                    if ([className isEqualToString:[ObjectMappingInfo oc_configurationMapNameKey]]) {
                        if ([obj isKindOfClass:[NSArray class]]) {
                            object[key] = [self objectFromSource:obj toInstanceOfClass:[NSArray class]];
                        }
                        else if ([obj isKindOfClass:[NSDictionary class]]) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *key2, id  _Nonnull obj2, BOOL * _Nonnull stop2) {
                                if (![[ObjectMappingInfo oc_javaClassNameKey] isEqualToString:key2]) {
                                    NSString *className = obj2[[ObjectMappingInfo oc_javaClassNameKey]];
                                    Class _class = [className internalClassName];
                                    NSString *FIXEDKEY = [key2 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                                    dic[FIXEDKEY] = [self objectFromSource:obj2 toInstanceOfClass:_class];
                                }
                            }];
                            object[key] = dic;
                        }
                    }
                    else {
                        Class _class = [className internalClassName];
                        object[key] = [self objectFromSource:obj toInstanceOfClass:_class];
                    }
                }
            }
        }];
    }
    else if (className.length > 0) {
        object = [self processDictionary:value forClass:class];
    }
    else {
        object = value;
    }
    
    if ([object isKindOfClass:[NSMutableDictionary class]]) {
        object = [object copy];
    }
    
    return object;
}

- (id)processDictionary:(NSDictionary *)source forClass:(Class)class {
    NSDictionary *normalizedSource = [self normalizedDictionaryFromDictionary:source forClass:class];
    
    id object = [self.instanceProvider emptyInstanceForClass:class];
    
    for (NSString *key in normalizedSource) {
        @autoreleasepool
        {
            ObjectMappingInfo *mappingInfo = [self.mappingProvider mappingInfoForClass:class andDictionaryKey:key];
            id value = normalizedSource[key];
            NSString *propertyName = @"";
            MappingTransformer mappingTransformer;
            Class objectType;
            id nestedObject;
            
            if (mappingInfo) {
                propertyName = [self.instanceProvider propertyNameForObject:object byCaseInsensitivePropertyName:mappingInfo.propertyKey];
                objectType = mappingInfo.objectType;
                mappingTransformer = mappingInfo.transformer;
            }
            else {
                propertyName = [self.instanceProvider propertyNameForObject:object byCaseInsensitivePropertyName:key];
                
                if (propertyName && ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]])) {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        objectType = [self classFromString:[self typeForProperty:propertyName andClass:class]];
                    }
                    
                    if (!objectType) {
                        objectType = [self classFromString:key];
                    }
                }
            }
            
            if (class && object && propertyName.length && [object respondsToSelector:NSSelectorFromString(propertyName)]) {
                ILog(@"Mapping key(%@) to property(%@) from data(%@)", key, propertyName, [value class]);
                
                if (mappingTransformer) {
                    nestedObject = mappingTransformer(value, source);
                }
                else if ([value isKindOfClass:[NSDictionary class]]) {
                    nestedObject = [self dr_processDictionary:value forClass:objectType];
                }
                else if ([value isKindOfClass:[NSArray class]]) {
                    nestedObject = [self processArray:value forClass:objectType];
                }
                else {
                    NSString *propertyTypeString = [self typeForProperty:propertyName andClass:class];
                    
                    // Convert NSString to NSDate if needed
                    if ([propertyTypeString isEqualToString:@"NSDate"]) {
                        if ([value isKindOfClass:[NSDate class]]) {
                            nestedObject = value;
                        }
                        else if ([value isKindOfClass:[NSString class]]) {
                            nestedObject = [self dateFromString:value forProperty:propertyName andClass:class];
                        }
                    }
                    // Convert NSString to NSNumber if needed
                    else if ([propertyTypeString isEqualToString:@"NSNumber"] && [value isKindOfClass:[NSString class]]) {
                        nestedObject = @([value doubleValue]);
                    }
                    // Convert NSNumber to NSString if needed
                    else if ([propertyTypeString isEqualToString:@"NSString"] && [value isKindOfClass:[NSNumber class]]) {
                        nestedObject = [value stringValue];
                    }
                    else {
                        nestedObject = value;
                    }
                }
                
                if ([nestedObject isKindOfClass:[NSNull class]]) {
                    nestedObject = nil;
                }
                
                [object setValue:nestedObject forKey:propertyName];
            }
            else {
                WLog(@"Unable to map from  key(%@) to property(%@) for class (%@)", key, propertyName, NSStringFromClass(class));
            }
        }
    }
    
    NSError *error;
    object = [self.instanceProvider upsertObject:object error:&error];
    
    if (error) {
        ELog(@"Attempt to update existing instance failed with error '%@' for class (%@) and object %@",
             error.localizedDescription,
             NSStringFromClass(class),
             object);
    }
    
    return object;
}

- (id)processArray:(NSArray *)value forClass:(Class)class {
    void (^originalBlock)(id, id, Class) = ^(id collection, id obj, Class c) {
        id nestedObject = [self objectFromSource:obj toInstanceOfClass:c];
        
        if (nestedObject) {
            [collection addObject:nestedObject];
        }
    };
    
    id collection = [self.instanceProvider emptyCollectionInstance];
    
    if ([value.firstObject isEqualToString:[OCBigDecimalNumber jsonMappedObject]] ||
        [value.firstObject isEqualToString:[ObjectMappingInfo oc_javaLongNumberNameKey]]) {
        collection = value.lastObject;
    }
    else if ([value.firstObject isEqualToString:[ObjectMappingInfo oc_javaArrayNameKey]] ||
             [value.firstObject isEqualToString:[ObjectMappingInfo oc_javaHashSetNameKey]] ||
             [value.firstObject isEqualToString:[ObjectMappingInfo oc_enumsPermissionNameKey]] ||
             [value.firstObject isEqualToString:[ObjectMappingInfo oc_enumsStationErrorCodeKey]]) {
        for (id objectInArray in value.lastObject) {
            if ([objectInArray isKindOfClass:[NSDictionary class]]) {
                NSString *collectionClassName = objectInArray[[ObjectMappingInfo oc_javaClassNameKey]];
                if (collectionClassName.length > 0) {
                    Class collectionClass = [collectionClassName internalClassName];
                    originalBlock(collection, objectInArray, collectionClass);
                }
                else {
                    originalBlock(collection, objectInArray, class);
                }
            }
            else {
                originalBlock(collection, objectInArray, class);
            }
        }
    }
    else if ([value.firstObject isEqualToString:[ObjectMappingInfo oc_javaMathTimestampNameKey]] ||
             [value.firstObject isEqualToString:[ObjectMappingInfo oc_javaSQLTimestampNameKey]] ||
             [value.firstObject isEqualToString:[ObjectMappingInfo oc_javaDateNameKey]]) {
        NSNumber *timestamp = value.lastObject;
        collection = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue];
    }
    else if ([value.firstObject isEqualToString:[ObjectMappingInfo oc_enumsStationOperationNameKey]]) {
        originalBlock(collection, value.lastObject, [NSArray class]);
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        collection = value;
    }
    else {
        NSAssert(NO, @"Wrong class name, need add parser for it!");
    }
    
    return collection;
}

- (Class)classFromString:(NSString *)className {
    Class result = Nil;
    
    NSString *mappedClass = [self.mappedClassNames objectForKey:className];
    if (mappedClass.length) {
        result = NSClassFromString(mappedClass);
        
        if (result) {
            return result;
        }
    }
    
    __weak typeof(self) weak = self;
    
    Class (^testClassName)(NSString *) = ^(NSString *classNameToTest) {
        Class clazz = NSClassFromString(classNameToTest);
        
        if (clazz) {
            [weak.mappedClassNames setObject:classNameToTest forKey:className];
        }
        
        return clazz;
    };
    
    // Handle underscore conversion (ex: game_states to an array of GameState objects)
    // Try using regex instead?
    if ([className rangeOfString:@"_"].length) {
        NSMutableString *newString = [NSMutableString string];
        
        [[className componentsSeparatedByString:@"_"] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            [newString appendString:obj.capitalizedString];
        }];
        
        className = newString;
    }
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
    
    if (className.length) {
        className = [className stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                       withString:[className substringToIndex:1].capitalizedString];
    }
    
    NSString *predictedClassName = className;
    if (testClassName(predictedClassName)) {
        return testClassName(predictedClassName);
    }
    
    predictedClassName = [NSString stringWithFormat:@"%@.%@", appName ,className];
    if (testClassName(predictedClassName)) {
        return testClassName(predictedClassName);
    }
    
    // EX: if keyword is "posts" try to find a class named "Post"
    if ([className hasSuffix:@"s"]) {
        NSString *classNameWithoutS = [className substringToIndex:className.length-1];
        
        predictedClassName = [NSString stringWithFormat:@"%@", classNameWithoutS];
        if (testClassName(predictedClassName)) {
            return testClassName(predictedClassName);
        }
        
        predictedClassName = [NSString stringWithFormat:@"%@.%@", appName, classNameWithoutS];
        if (testClassName(predictedClassName)) {
            return testClassName(predictedClassName);
        }
    }
    
    // EX: if keyword is "addresses" try to find a class named "Address"
    if ([className hasSuffix:@"es"]) {
        NSString *classNameWithoutEs = [className substringToIndex:className.length-2];
        
        predictedClassName = [NSString stringWithFormat:@"%@", classNameWithoutEs];
        if (testClassName(predictedClassName)) {
            return testClassName(predictedClassName);
        }
        
        predictedClassName = [NSString stringWithFormat:@"%@.%@", appName, classNameWithoutEs];
        if (testClassName(predictedClassName)) {
            return testClassName(predictedClassName);
        }
    }
    
    return result;
}

- (NSDate *)dateFromString:(NSString *)string forProperty:(NSString *)property andClass:(Class)class {
    NSDate *date;
    NSDateFormatter *customDateFormatter = [self.mappingProvider dateFormatterForClass:class andPropertyKey:property];
    
    if (customDateFormatter) {
        date = [customDateFormatter dateFromString:string];
        ILog(@"attempting to convert date '%@' on property '%@' for class [%@] using 'customDateFormatter' (%@)", date, property, NSStringFromClass(class), customDateFormatter.dateFormat);
    }
    else if (self.defaultDateFormatter) {
        date = [self.defaultDateFormatter dateFromString:string];
        ILog(@"attempting to convert '%@' on property '%@' for class [%@] using 'defaultDateFormatter' (%@)", date, property, NSStringFromClass(class), self.defaultDateFormatter.dateFormat);
    }
    
    if (!date) {
        for (NSDateFormatter *dateFormatter in self.commonDateFormaters) {
            date = [dateFormatter dateFromString:string];
            ILog(@"attempting to convert date(%@) on property(%@) for class(%@) using 'commonDateFormaters' (%@)", date, property, NSStringFromClass(class), dateFormatter.dateFormat);
            
            if (date) {
                ILog(@"Converted date(%@) on property(%@) for class(%@) using 'commonDateFormaters' (%@)", date, property, NSStringFromClass(class), dateFormatter.dateFormat);
                break;
            }
        }
    }
    
    if (!date) {
        ELog(@"Unable to convert date(%@) on property(%@) for class(%@)", date, property, NSStringFromClass(class));
    }
    
    return date;
}

- (NSMutableArray *)commonDateFormaters {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self->_commonDateFormaters = [NSMutableArray array];
        
        NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
        formatter1.dateFormat = @"yyyy-MM-dd";
        [self->_commonDateFormaters addObject:formatter1];
        
        NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
        formatter2.dateFormat = @"MM/dd/yyyy";
        [self->_commonDateFormaters addObject:formatter2];
        
        NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
        formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ";
        [self->_commonDateFormaters addObject:formatter3];
        
        NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
        formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        [self->_commonDateFormaters addObject:formatter4];
        
        NSDateFormatter *formatter5 = [[NSDateFormatter alloc] init];
        formatter5.dateFormat = @"MM/dd/yyyy HH:mm:ss aaa";
        [self->_commonDateFormaters addObject:formatter5];
        
        NSDateFormatter *formatter6 = [[NSDateFormatter alloc] init];
        formatter6.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        [self->_commonDateFormaters addObject:formatter6];
    });
    
    return _commonDateFormaters;
}

- (NSString *)typeForProperty:(NSString *)property andClass:(Class)class {
    NSString *key = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(class), property];
    NSString *className = [self.mappedPropertyNames objectForKey:key];
    if (className.length) {
        return className;
    }
    
    const char *type = property_getAttributes(class_getProperty(class, property.UTF8String));
    NSString *typeString = @(type);
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = attributes.firstObject;
    className = [[[typeAttribute substringFromIndex:1]
                  stringByReplacingOccurrencesOfString:@"@" withString:@""]
                 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    NSAssert(className.length, @"Wrong Class for key: %@", key);
    if (className.length) {
        [self.mappedClassNames setObject:className forKey:key];
    }
    
    return className;
}

+ (id)mapDTONode:(id)node {
    if ([node isKindOfClass:[NSArray class]]) {
        return [[ObjectMapper sharedInstance] processArray:node forClass:[node class]];
    }
    else if ([node isKindOfClass:[NSDictionary class]]) {
        Class _class = [node[[ObjectMappingInfo oc_javaClassNameKey]] internalClassName];
        
        if (_class) {
            return [[ObjectMapper sharedInstance] objectFromSource:node toInstanceOfClass:_class];
        }
        
        return [[ObjectMapper sharedInstance] dr_processDictionary:node forClass:[NSDictionary class]];
    }
    
    return node;
}

@end
