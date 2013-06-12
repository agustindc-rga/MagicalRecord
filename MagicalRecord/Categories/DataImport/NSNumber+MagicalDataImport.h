//
//  NSNumber+MagicalDataImport.h
//  Magical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (MagicalRecord_DataImport)

- (NSString *) lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
- (id) relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo;

@end
