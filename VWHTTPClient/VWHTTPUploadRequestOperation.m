//
//  VWHTTPUploadRequestOperation.m
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWHTTPUploadRequestOperation.h"

typedef void (^AFURLConnectionProgressiveOperationProgressBlock)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

@interface VWHTTPUploadRequestOperation ()
@property (nonatomic, copy) AFURLConnectionProgressiveOperationProgressBlock progressiveUploadProgress;
@end

@implementation VWHTTPUploadRequestOperation

#pragma mark - Private

- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

- (void)setProgressiveUploadProgressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    self.progressiveUploadProgress = block;
}

- (void)setProgressiveUploadCallbackQueue:(dispatch_queue_t)progressiveUploadCallbackQueue {
    if (progressiveUploadCallbackQueue != _progressiveUploadCallbackQueue) {
        if (_progressiveUploadCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_release(_progressiveUploadCallbackQueue);
#endif
            _progressiveUploadCallbackQueue = NULL;
        }
        
        if (_progressiveUploadCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(_progressiveUploadCallbackQueue);
#endif
            _progressiveUploadCallbackQueue = progressiveUploadCallbackQueue;
        }
    }
}


- (void)connection:(NSURLConnection __unused *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    
    [super connection:connection didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    
    _totalContentLength = totalBytesExpectedToWrite;
    
    if (self.progressiveUploadProgress) {
        dispatch_async(self.progressiveUploadCallbackQueue ?: dispatch_get_main_queue(), ^{
            self.progressiveUploadProgress(self,bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}

@end
