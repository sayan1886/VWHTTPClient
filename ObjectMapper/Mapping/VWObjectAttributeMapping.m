//
//  VWEntityAttributeMapping.m
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWObjectAttributeMapping.h"

@implementation VWObjectAttributeMapping

@synthesize sourceKeyPath = _sourceKeyPath;
@synthesize destinationKeyPath = _destinationKeyPath;
@synthesize destinationAttributeType = _destinationAttributeType;
@synthesize participateInProxy = _participateInProxy;

#pragma mark - NSObject

- (id)initWithSourceKeyPath:(NSString *)sourceKeyPath andDestinationKeyPath:(NSString *)destinationKeyPath {
    NSAssert(sourceKeyPath != nil, @"Cannot define an element mapping an element name to map from");
    NSAssert(destinationKeyPath != nil, @"Cannot define an element mapping without a property to apply the value to");
    
    if (self = [super init]) {
        self.sourceKeyPath = sourceKeyPath;
        self.destinationKeyPath = destinationKeyPath;
        self.participateInProxy = NO;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"VWObjectKeyPathMapping: %@ => %@", self.sourceKeyPath, self.destinationKeyPath];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    VWObjectAttributeMapping* copy = [[[self class] allocWithZone:zone] initWithSourceKeyPath:self.sourceKeyPath andDestinationKeyPath:self.destinationKeyPath];
    return copy;
}

+ (VWObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath {
    VWObjectAttributeMapping *mapping = [[self alloc] initWithSourceKeyPath:sourceKeyPath andDestinationKeyPath:destinationKeyPath];
    return mapping;
}

+ (VWObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withDestinationType:(Class)type{
    return [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withDestinationType:type readyForProxy:NO];
}

+ (VWObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withDestinationType:(Class)type readyForProxy:(BOOL)shouldParticipate{
    VWObjectAttributeMapping *mapping = [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    mapping.destinationAttributeType = type;
    mapping.participateInProxy = shouldParticipate;
    return mapping;
}

@end
