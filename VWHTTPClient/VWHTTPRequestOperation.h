//
//  VWHTTPRequestOperation.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

@interface VWHTTPRequestOperation : AFHTTPRequestOperation

/**
 A String value that defines each operation with an uniques identifier.
 
 this operation may be and Downlaod or Upload operation
 */

@property (nonatomic, strong) NSString *operationId;

@property (nonatomic, strong) NSString* rootKeyPath;

/**
 A Class value that denotes the calling class, or the request comes from
 
 */

@property (nonatomic, assign) Class objectClass;

/**
 A Boolean value that defines the outcome of the request, i.e the Response needs to mapped with existing classes
 */

@property (nonatomic, assign) BOOL allowMapping;

/**
 A Inteager value that tells the retry count for the opertaion
 */

@property (nonatomic, assign, readonly) NSUInteger retryCount;

/**
 A Inteager value defines maximum retry for the operation
 */

@property (nonatomic, assign) NSUInteger maxRetryCount;

@property (nonatomic, assign, readonly) DownloadingFileStatus status;

/**
 A String value that defines the filename for downloaded file.
*/

@property (nonatomic, strong) NSString *fileName;

/**
 A long long value that defines the data file size.
 */

@property (nonatomic, assign) unsigned long long fileSize;

/**
 A float value that defines the data transfer progress.
 */

@property (nonatomic, assign, readonly) float dataTransferProgress;

@end
