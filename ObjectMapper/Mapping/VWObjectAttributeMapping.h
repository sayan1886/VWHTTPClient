//
//  VWEntityAttributeMapping.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VWObjectAttributeMapping : NSObject <NSCopying>{
    NSString *_sourceKeyPath;
    NSString *_destinationKeyPath;
    Class _destinationAttributeType;
    BOOL _participateInProxy;
}

@property (nonatomic, assign) Class destinationAttributeType;

@property (nonatomic, retain) NSString *sourceKeyPath;

@property (nonatomic, retain) NSString *destinationKeyPath;

@property (nonatomic, assign) BOOL participateInProxy;

/**
 Defines a mapping from one keyPath to another within an object mapping
 */
+ (VWObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath;

+ (VWObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withDestinationType:(Class)type;

+ (VWObjectAttributeMapping *)mappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withDestinationType:(Class)type readyForProxy:(BOOL)shouldParticipate;

@end
