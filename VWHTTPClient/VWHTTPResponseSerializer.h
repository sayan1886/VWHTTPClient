//
//  VWHTTPResponseSerializer.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "AFURLResponseSerialization.h"

#import "VWObjectMapping.h"

@interface VWHTTPResponseSerializer : AFHTTPResponseSerializer

@property (strong, readwrite) NSString *rootKeyPath;

@property (strong, readwrite) VWObjectMapping *objectMapping;

@end
