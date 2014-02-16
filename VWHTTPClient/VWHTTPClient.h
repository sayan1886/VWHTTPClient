//
//  VWHTTPClient.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VWHTTPDownloadRequestOperation.h"
#import "VWHTTPUploadRequestOperation.h"

#import "VWObjectMapping.h"

@interface VWHTTPClient : AFHTTPRequestOperationManager

+ (instancetype)sharedClient;

@property (nonatomic, readwrite, strong) NSOperationQueue *downloadsQueue;

@property (nonatomic, readwrite, strong) NSOperationQueue *uploadsQueue;

- (VWHTTPRequestOperation *) VWHTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                       success:(void (^)(VWHTTPRequestOperation *operation, id responseObject))success
                                                       failure:(void (^)(VWHTTPRequestOperation *operation, NSError *error))failure;

- (id)downloadFile:(NSString *)URLString
        parameters:(NSDictionary *)parameters
         localPath:(NSString*)path
           success:(void (^)(VWHTTPDownloadRequestOperation *operation, id responseObject))success
           failure:(void (^)(VWHTTPDownloadRequestOperation *operation, NSError *error))failure
     progressBlock:(void (^)(VWHTTPDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile))block;


- (id)uploadFile:(NSString *)URLString
      parameters:(NSDictionary *)parameters
       localPath:(NSString*)path
         success:(void (^)(VWHTTPUploadRequestOperation *operation, id responseObject))success
         failure:(void (^)(VWHTTPUploadRequestOperation *operation, NSError *error))failure
   progressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

- (id)uploadFile:(NSString *)URLString
         headers:(NSDictionary *)headers
       localPath:(NSString*)path
         success:(void (^)(VWHTTPUploadRequestOperation *operation, id responseObject))success
         failure:(void (^)(VWHTTPUploadRequestOperation *operation, NSError *error))failure
   progressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;


- (id)uploadDataTo:(NSString *)URLString
           headers:(NSDictionary *)headers
          fileName:(NSString *)fname
              data:(NSData *)data
           success:(void (^)(VWHTTPUploadRequestOperation *operation, id responseObject))success
           failure:(void (^)(VWHTTPUploadRequestOperation *operation, NSError *error))failure
     progressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;


- (id)sendRequest:(NSMutableURLRequest*)request withMapping:(VWObjectMapping*)mapping allowMapping:(BOOL)allowMapping success:(void (^)(VWHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(VWHTTPRequestOperation *operation, NSError *error))failure;



@end
