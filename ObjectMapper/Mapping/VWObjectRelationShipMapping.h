//
//  VWObjectRelationShipMapping.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWObjectAttributeMapping.h"

@class VWObjectMapping;

@interface VWObjectRelationShipMapping : VWObjectAttributeMapping{
    VWObjectMapping * _mapping;
    BOOL _reversible;
}

@property (nonatomic, retain) VWObjectMapping * mapping;
@property (nonatomic, assign) BOOL reversible;

+ (VWObjectRelationShipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(VWObjectMapping *)objectMapping;

+ (VWObjectRelationShipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(VWObjectMapping *)objectMapping reversible:(BOOL)reversible;


@end
