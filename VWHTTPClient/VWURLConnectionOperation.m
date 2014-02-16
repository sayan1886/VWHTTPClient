//
//  VWURLConnectionOperation.m
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWURLConnectionOperation.h"

@implementation VWURLConnectionOperation

@dynamic lock;


- (NSUInteger)hash {
    return [[[self.request URL] absoluteString] hash];
}

@end
