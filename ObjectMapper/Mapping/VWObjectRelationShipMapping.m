//
//  VWObjectRelationShipMapping.m
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWObjectRelationShipMapping.h"
#import "VWObjectMapping.h"

@implementation VWObjectRelationShipMapping

@synthesize mapping = _mapping;
@synthesize reversible = _reversible;

+ (VWObjectRelationShipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(VWObjectMapping *)objectMapping reversible:(BOOL)reversible {
    VWObjectRelationShipMapping* relationshipMapping = (VWObjectRelationShipMapping*) [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    relationshipMapping.reversible = reversible;
    relationshipMapping.mapping = objectMapping;
    return relationshipMapping;
}

+ (VWObjectRelationShipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(VWObjectMapping *)objectMapping {
    return [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectMapping reversible:YES];
}

- (id)copyWithZone:(NSZone *)zone {
    VWObjectRelationShipMapping* copy = [super copyWithZone:zone];
    copy.mapping = self.mapping;
    copy.reversible = self.reversible;
    return copy;
}


@end
