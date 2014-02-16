//
//  VWURLConnectionOperation.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "AFURLConnectionOperation.h"

@interface VWURLConnectionOperation : AFURLConnectionOperation

@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;

- (NSUInteger)hash;

@end
