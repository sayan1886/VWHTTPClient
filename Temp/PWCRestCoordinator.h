//
//  PWCRestCoordinator.h
//  PlanwellCollaboration
//
//  Created by Abhijit Mukherjee on 05/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PWCDataManager.h"
#import "PWCHTTPClient.h"

#define SHOW_NETWORK_MONITOR @"__network_monitor__"
#define NOTIFY_FOR_NEW_OPID @"__new_opearation_id__"

typedef enum {
    kGetRequest = 1,
    kPostRequest,
    kPutRequest,
    kDeleteRequest
}RequestType;

typedef enum {
    PWCObjectMappingProviderContextObjectsByKeyPath = 1000,
    PWCObjectMappingProviderContextObjectsByType,
} PWCObjectMappingProviderContext;

@class QWatchedOperationQueue;
@class PWCEntityMapping;

@protocol PWCOperationTarget <NSObject>

- (NSThread*)targetThreadForOperationCallbacks;

@end
@interface PWCRestCoordinator : NSObject<PWCOperationTarget>{

    NSError *                       _error;
    CFMutableDictionaryRef  _operationToCompletionAction;
    NSThread *              _targetThread;
    NSMutableDictionary *_mappingProvider;
}

@property (nonatomic, copy, readonly ) NSError *error;              // nil if no error
@property (retain, readonly) NSThread *targetThread;
@property (retain, nonatomic) NSMutableDictionary *mappingProvider;
//SMB:
@property (nonatomic, retain) QWatchedOperationQueue *mapperQueue;

/**
 Adds an object mapping to the provider for later retrieval. The mapping is not bound to a particular keyPath and
 must be explicitly set on an instance of RKObjectLoader or RKObjectMappingOperation to be applied. This is useful
 in cases where the remote system does not namespace resources in a keyPath that can be used for disambiguation.
 
 You can retrieve mappings added to the provider by invoking objectMappingsForClass: and objectMappingForClass:
 
 @param objectMapping An object mapping instance we wish to register with the provider.
 @see objectMappingsForClass:
 @see objectMappingForClass:
 */
+ (void)addObjectMapping:(PWCEntityMapping *)objectMapping;
+ (void)setMapping:(PWCEntityMapping*)mapping forKeyPath:(NSString*)keyPath;
+ (PWCEntityMapping*)mappingForKeyPath:(NSString*)keyPath;
+ (NSArray *)objectMappingsForClass:(Class)theClass ;
+ (PWCEntityMapping *)objectMappingForClass:(Class)theClass ;
+ (NSString *)_generateUUIDString;


+ (id)restManager;
+ (void)doCleanups;

// they all return the operation Ids...

//Post
+ (id)postRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header andBody:(NSString*)body completionHandler:(CompletionCallbackBlock)handler;
+ (id)postRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)model withHeader:(NSDictionary*)header andBody:(NSString*)body allowMapping:(BOOL)mapping completionHandler:(CompletionCallbackBlock)handler;
+ (id)postRequest:(NSString*)urlString withHeader:(NSDictionary*)header completionHandler:(CompletionCallbackBlock)handler;
+ (id)postRequest:(NSString*)urlString withHeader:(NSDictionary*)header allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler;
+ (id)postRequest:(NSString*)urlString withHeader:(NSDictionary*)header andBody:(NSString*)body completionHandler:(CompletionCallbackBlock)handler;

//Get
+ (id)getRequest:(NSString*)urlString withHeader:(NSDictionary*)header allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler;
+ (id)getRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header completionHandler:(CompletionCallbackBlock)handler;
+ (id)getRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header  allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler;

//download & upload
//for downloading resources, e.g. iamges, vdo the result is only the response body ; for kTargetEntity
//+ (id)downloadResource:(NSString*)urlString completionHandler:(CompletionCallbackBlock)handler;
+ (id)downloadResource:(NSString*)urlString toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler;
+ (id)uploadRequest:(NSString*)uploadUrlString fileName:(NSString*)fileName withHeader:(NSDictionary*)header andBody:(NSData*)fileData completionHandler:(CompletionCallbackBlock)handler;
+ (id)uploadRequest:(NSString*)uploadUrlString fileName:(NSString*)fileName withHeader:(NSDictionary*)header andBody:(NSData*)fileData completionHandler:(CompletionCallbackBlock)handler intermediate:(IntermediateCallbackBlock)intermediateCallback;

//Project Sync
+ (id)syncProjectWithID:(NSString*)projectID;

//Cancel Operation
+ (void)cancelOperationsUsingMapping:(PWCEntityMapping*)mapping;
+ (void)cancelAllOperations;
+ (void)cancelAllRESTAndDownloadOperations;
+ (void)cancelAllHeavyOperations;
+ (NSInteger)operationCount;
+ (void)cancelOperationWithID:(id)operationID;
+ (void)cancelOperationAtIndex:(NSInteger)index;
+ (BOOL)canCancelOperationAtIndex:(NSInteger)index;
+ (NSInteger)heavyOperationCount;

//Utility methods
- (int)runningOperationCount;
- (NSArray*)allUploadOperations;
- (NSArray*)allDownloadOperations;
- (NSArray*)allRESTOperations;
+ (NSString *)tempDirectoryPath;
+ (NSString *)cachesDirectoryPath;
+ (void)setCallingClass:(Class)callingClass;
+ (NSMutableURLRequest*)prepareRequestFromUrl:(NSString*)urlString withHeader:(NSDictionary*)headerFields;

@end
