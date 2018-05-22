//
//  OCBigDecimalNumber.m
//  OCMapper
//
//  Created by Vitalii Parovishnyk on 6/1/17.
//  Copyright © 2017 Driivz. All rights reserved.
//

#import "OCBigDecimalNumber.h"

@implementation OCBigDecimalNumber

+ (OCBigDecimalNumber *)getNumber:(NSArray *)object {
    NSAssert(object.count == 2, @"Wgong Format");
    return object.lastObject;
}

+ (id)jsonMappedObject {
    return @"java.math.BigDecimal";
}

@end
