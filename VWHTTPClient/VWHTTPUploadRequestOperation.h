//
//  VWHTTPUploadRequestOperation.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWHTTPRequestOperation.h"

@interface VWHTTPUploadRequestOperation : VWHTTPRequestOperation

/**
 The callback dispatch queue on progressive download. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, assign) dispatch_queue_t progressiveUploadCallbackQueue;

@property (assign, readonly) long long totalContentLength;


- (void)setProgressiveUploadProgressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

@end
