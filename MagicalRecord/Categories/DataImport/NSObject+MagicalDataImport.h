//
//  NSDictionary+MagicalDataImport.h
//  Magical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MagicalRecord_DataImport)

- (NSString *) lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
- (id) valueForAttribute:(NSAttributeDescription *)attributeInfo;

- (NSString *) lookupKeyForRelationship:(NSRelationshipDescription *)relationshipInfo;
- (id) relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo;

@end
