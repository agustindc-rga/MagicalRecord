//
//  NSNumber+MagicalDataImport.m
//  Magical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSNumber+MagicalDataImport.h"



@implementation NSNumber (MagicalRecord_DataImport)

- (id) relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    return self;
}

- (NSString *) lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo
{
    return nil;
}

@end
