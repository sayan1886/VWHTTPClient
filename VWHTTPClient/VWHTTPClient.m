    //
    //  VWHTTPClient.m
    //  VWHTTPClient
    //
    //  Created by Sayan Chatterjee on 16/02/14.
    //  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
    //

#import "VWHTTPClient.h"

#import "VWHTTPDownloadResponseSerializer.h"

@interface VWHTTPClient ()

- (VWHTTPDownloadRequestOperation *)fileDownloadOperationWithRequest:(NSURLRequest*)request localPath:(NSString*)path; //need to check resume operation

- (VWHTTPUploadRequestOperation *)fileUploadOperationWithRequest:(NSURLRequest*)request;

@end

@implementation VWHTTPClient

#pragma mark - Initialization

+ (instancetype)sharedClient {
        // Persistent instance.
	static VWHTTPClient *_default = nil;
	
        // Small optimization to avoid wasting time after the
        // singleton being initialized.
	if (_default != nil)
        {
		return _default;
        }
        // Allocates once with Grand Central Dispatch (GCD) routine.
        // It's thread safe.
	static dispatch_once_t safer;
	dispatch_once(&safer, ^(void)
				  {
                  _default = [[VWHTTPClient alloc] initWithBaseURL:nil];
				  });
	return _default;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    self.downloadsQueue = [[NSOperationQueue alloc] init];
    [_downloadsQueue setMaxConcurrentOperationCount:2];
    
    self.uploadsQueue = [[NSOperationQueue alloc] init];
    [_uploadsQueue setMaxConcurrentOperationCount:2];
    
        //accept any content type
    self.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    return self;
}

#pragma mark - Utility methods

- (NSString *)_generateUUIDString
{
    CFUUIDRef       uuid;
    CFStringRef     uuidStr;
    NSString *      result;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
        // create a new CFStringRef (toll-free bridged to NSString)
        // that you own
    result = CFBridgingRelease(uuidStr);//(__bridge NSString *)uuidStr ;
    
        // release the UUID
    CFRelease(uuid);
    
        //CFRelease(uuidStr);
    
    return result;
}

- (VWHTTPRequestOperation *) VWHTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                       success:(void (^)(VWHTTPRequestOperation *operation, id responseObject))success
                                                       failure:(void (^)(VWHTTPRequestOperation *operation, NSError *error))failure
{
    VWHTTPRequestOperation *operation = [[VWHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = self.responseSerializer;
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
    
    [operation setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure];
    
    return operation;
}


- (VWHTTPDownloadRequestOperation *)fileDownloadOperationWithRequest:(NSURLRequest*)request localPath:(NSString*)path {
    VWHTTPDownloadRequestOperation *operation = [[VWHTTPDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:NO];//need to test if you change shouldResume to YES
    operation.responseSerializer = [VWHTTPDownloadResponseSerializer serializer];
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
    operation.deleteTempFileOnCancel = YES;
    return operation;
}

- (VWHTTPUploadRequestOperation *)fileUploadOperationWithRequest:(NSURLRequest*)request {
    VWHTTPUploadRequestOperation *operation = [[VWHTTPUploadRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = self.responseSerializer;
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
    
    return operation;
}

#pragma mark - Download Operation

- (id)downloadFile:(NSString *)URLString
        parameters:(NSDictionary *)parameters
         localPath:(NSString*)path
           success:(void (^)(VWHTTPDownloadRequestOperation *operation, id responseObject))success
           failure:(void (^)(VWHTTPDownloadRequestOperation *operation, NSError *error))failure
     progressBlock:(void (^)(VWHTTPDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile))progress {
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&error];
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    VWHTTPDownloadRequestOperation *operation = [self fileDownloadOperationWithRequest:request localPath:path];
    operation.fileName = [path lastPathComponent];
        //operation.timeStamp = [NSDate date];
    [operation setProgressiveDownloadProgressBlock:(void (^)(VWHTTPDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile))progress];
    [operation setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure];
    
    NSString *opid = [self _generateUUIDString];
    
    operation.operationId = opid;
    
    [self enqueueOperation:operation];
    
    return opid;
}

#pragma mark - Upload Operation

- (id)uploadFile:(NSString *)URLString
      parameters:(NSDictionary *)parameters
       localPath:(NSString*)path
         success:(void (^)(VWHTTPUploadRequestOperation *operation, id responseObject))success
         failure:(void (^)(VWHTTPUploadRequestOperation *operation, NSError *error))failure
   progressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSInputStream *input = [NSInputStream inputStreamWithFileAtPath:path];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
        unsigned long long fileSize = [attributes fileSize]; // in bytes
        NSString *contentType = nil;
        NSString *checkExt = [path.pathExtension lowercaseString];
        if ( [checkExt isEqual:@"png"] ) {
            contentType = @"image/png";
        } else if ( [checkExt isEqual:@"jpg"] ) {
            contentType = @"image/jpeg";
        } else if ( [checkExt isEqual:@"gif"] ) {
            contentType = @"image/gif";
        } else {
            contentType = @"application/octet-stream";
        }
        [formData appendPartWithInputStream:input name:@"fileContents" fileName:[path lastPathComponent] length:fileSize mimeType:contentType];
    } error:&error];
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    VWHTTPUploadRequestOperation *operation = [self fileUploadOperationWithRequest:request];
    operation.fileName = [path lastPathComponent];//setting filename
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    unsigned long long fileSize = [attributes fileSize]; // in bytes
    operation.fileSize = fileSize;//setting file size
                                  //operation.timeStamp = [NSDate date];
    [operation setProgressiveUploadProgressBlock:block];
    [operation setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure];
    
    NSString *opid = [self _generateUUIDString];
    
    operation.operationId = opid;
    
    [self enqueueOperation:operation];
    
    return opid;
}

- (id)uploadFile:(NSString *)URLString
         headers:(NSDictionary *)headers
       localPath:(NSString*)path
         success:(void (^)(VWHTTPUploadRequestOperation *operation, id responseObject))success
         failure:(void (^)(VWHTTPUploadRequestOperation *operation, NSError *error))failure
   progressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    
    NSLog(@"Will Upload:%@",path);
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSInputStream *input = [NSInputStream inputStreamWithFileAtPath:path];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
        unsigned long long fileSize = [attributes fileSize]; // in bytes
        NSString *contentType = nil;
        NSString *checkExt = [path.pathExtension lowercaseString];
        if ( [checkExt isEqual:@"png"] ) {
            contentType = @"image/png";
        } else if ( [checkExt isEqual:@"jpg"] ) {
            contentType = @"image/jpeg";
        } else if ( [checkExt isEqual:@"gif"] ) {
            contentType = @"image/gif";
        } else {
            contentType = @"application/octet-stream";
        }
        [formData appendPartWithInputStream:input name:@"fileContents" fileName:[path lastPathComponent] length:fileSize mimeType:contentType];
    } error:&error];
    if(headers) {
        [request setAllHTTPHeaderFields:headers];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    VWHTTPUploadRequestOperation *operation = [self fileUploadOperationWithRequest:request];
    operation.fileName = [path lastPathComponent];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    unsigned long long fileSize = [attributes fileSize];
    operation.fileSize = fileSize;
        //operation.timeStamp = [NSDate date];
    [operation setProgressiveUploadProgressBlock:block];
    [operation setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure];
    
    NSString *opid = [self _generateUUIDString];
    
    operation.operationId = opid;
    
    [self enqueueOperation:operation];
    
    return opid;
}

- (id)uploadDataTo:(NSString *)URLString
           headers:(NSDictionary *)headers
          fileName:(NSString *)fname
              data:(NSData *)data
           success:(void (^)(VWHTTPUploadRequestOperation *operation, id responseObject))success
           failure:(void (^)(VWHTTPUploadRequestOperation *operation, NSError *error))failure
     progressBlock:(void (^)(VWHTTPUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSString *contentType = nil;
        NSString *checkExt = [fname.pathExtension lowercaseString];
        if ( [checkExt isEqual:@"png"] ) {
            contentType = @"image/png";
        } else if ( [checkExt isEqual:@"jpg"] ) {
            contentType = @"image/jpeg";
        } else if ( [checkExt isEqual:@"gif"] ) {
            contentType = @"image/gif";
        } else {
            contentType = @"application/octet-stream";
        }
        
        [formData appendPartWithFileData:data name:@"fileContents" fileName:fname mimeType:contentType];
        [formData throttleBandwidthWithPacketSize:kAFUploadStream3GSuggestedPacketSize delay:0.5];
    } error:&error];
    if(headers) {
        [request setAllHTTPHeaderFields:headers];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    VWHTTPUploadRequestOperation *operation = [self fileUploadOperationWithRequest:request];
    operation.fileName = fname;
    operation.fileSize = [data length];
        //operation.timeStamp = [NSDate date];
    [operation setProgressiveUploadProgressBlock:block];
    [operation setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure];
    
    NSString *opid = [self _generateUUIDString];
    
    operation.operationId = opid;
    
    [self enqueueOperation:operation];
    
    return opid;
}


#pragma mark - REST Operation

- (id)sendRequest:(NSMutableURLRequest*)request withMapping:(VWObjectMapping*)mapping allowMapping:(BOOL)allowMapping success:(void (^)(VWHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(VWHTTPRequestOperation *operation, NSError *error))failure {
    
    VWHTTPRequestOperation *operation = [self VWHTTPRequestOperationWithRequest:request success:success failure:failure];
    
    operation.allowMapping = allowMapping;
    
    NSString *key = nil;
    if(mapping){
        key = [mapping.objectClass performSelector:@selector(rootKeyPath)];
        
        if (key) {
            operation.rootKeyPath = key;
        }
        else {
            operation.objectClass = mapping.objectClass;
        }
    }
    else {
        key = [request.URL absoluteString];
        operation.rootKeyPath = key;
    }
    
    NSString *opid = [self _generateUUIDString];
    
    operation.operationId = opid;
    
    [self.operationQueue addOperation:operation];
    
    return opid;
}

#pragma mark - Enqueue Operation

- (BOOL)enqueueOperation:(VWHTTPRequestOperation *)operation
{
    NSLog(@"OperationID:%@",operation.operationId);
    if ([operation isKindOfClass:[VWHTTPDownloadRequestOperation class]])
        {
        [self.downloadsQueue addOperation:operation];
        }
    else if ([operation isKindOfClass:[VWHTTPUploadRequestOperation class]]){
        [self.uploadsQueue addOperation:operation];
    }
    
    return YES;
}


@end
