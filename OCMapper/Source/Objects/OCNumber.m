//
//  OCNumber.m
//  OCMapper
//
//  Created by Vitalii Parovishnyk on 6/5/17.
//  Copyright © 2017 Driivz. All rights reserved.
//

#import "OCNumber.h"
#import "NSObject+ObjectMapper.h"

@implementation OCNumber

+ (id)jsonMappedValue:(id)value {
    value = value ?: @"";
    return @[[[self class] jsonMappedObject], value];
}

@end
