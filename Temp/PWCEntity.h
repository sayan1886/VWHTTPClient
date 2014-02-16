//
//  PWCEntity.h
//  PlanwellCollaboration
//
//  Created by Abhijit Mukherjee on 05/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PWCRestCoordinator.h"
#import "PWCServices.h"
#import "PWCNetwork.h"
#import "PWCEntityMapping.h"
#import "NSObject+SBJSON.h"
#import "NSString+InflectionSupport.h"
#import "NSObject+PropertyList.h"
#import "MAZeroingWeakRef.h"

#define kTargetEntity @"TargetEntity"
#define kResponseHeaderEntity @"ResponseHeader"
#define kUserName @"UserName"
#define kUserCompany @"UserCompany"
#define kPWUserID @"PWUserID"

@class PWCShareEntity;

@interface PWCEntity : NSObject
@property (nonatomic, retain) NSNumber *markedForDeletion;
@property (nonatomic, retain) NSString *operationId;
@property (nonatomic, assign) BOOL detailsFetched;

+ (NSString*)getRequestBody:(id)inputBodyObj;
+ (NSString *)getURLWithServicePath:(NSString*)svcPath;
+ (NSString *)rootKeyPath;
+ (PWCEntityMapping*)entityMapping;
/*receiver responsible for releasing the returned new object*/
+ (NSMutableDictionary*)newHeaderForOperations;
+ (NSMutableDictionary*)newHeaderForOperationsIncludePage:(NSInteger)pageNo;
+ (void)getEntitiesOnCompletion:(CompletionCallbackBlock)callback;
+ (void)getEntitiesForPageNumber:(NSInteger)pageNo onCompletion:(CompletionCallbackBlock)callback;
+ (void)getEntitiesFrom:(NSString*)path onCompletion:(CompletionCallbackBlock)handler;
+ (void)getEntitiesFrom:(NSString*)path withHeader:(NSDictionary*)header onCompletion:(CompletionCallbackBlock)handler;

+ (void)postEntitites:(NSDictionary*)requestBody toPath:(NSString*)thePath onCompletion:(CompletionCallbackBlock)handler;
+ (void)postEntitites:(id)requestBody toPath:(NSString*)thePath mappable:(BOOL)isMappable onCompletion:(CompletionCallbackBlock)handler;
+ (void)postJSONEntitites:(NSString*)JSONbody toPath:(NSString*)thePath mappable:(BOOL)isMappable onCompletion:(CompletionCallbackBlock)handler;

+ (void)deleteEntities:(NSArray*)entitiesToDelete atPath:(NSString*)thePath onCompletion:(CompletionCallbackBlock)handler;
+ (void)cancelAllRelatedOperations;
+ (void)removeCachesFiles;
+ (NSString*)getMarkupIPPath;
+ (NSString*)getMarkupIPPutPath;
// here `fileName` is the GUID of the file i.e. <GUID>.<extension>
+ (NSString*)getMarkupXMLPathForFileName:(NSString*)fileName;

- (void)uploadImageAtPath:(NSString*)destinationPath fileName:(NSString*)fileNameOrNil withData:(NSData*)srcData onCompletion:(CompletionCallbackBlock)callback;
- (void)uploadImageAtPath:(NSString*)destinationPath fileName:(NSString*)fileNameOrNil withData:(NSData*)srcData onCompletion:(CompletionCallbackBlock)callback intermediate:(IntermediateCallbackBlock)intermediateCallBack;
- (void)updateEntityAtPath:(NSString*)path onCompletion:(CompletionCallbackBlock)callback;
- (void)createEntityAtPath:(NSString*)path onCompletion:(CompletionCallbackBlock)callback;
- (id) proxyForJson;
- (MAZeroingWeakRef*)newWeakReferenceOfSelf;
- (void)fetchDetailFrom:(NSString*)aPath OnCompletion:(CompletionCallbackBlock)callback;
//an empty new instance which subclasses override so that they can fill only those properties
//that needed by service
- (PWCEntity*)newDeleteInstance;
- (PWCEntity*)newUpdateInstance;
//Common super class method for returning new instance and then the children decide what properties
//to present for CRUD operations
- (PWCEntity*)newCRUDInstance;
- (PWCShareEntity*)createShareEntity;

@end

@interface PWCError : PWCEntity 

@property(nonatomic,retain) NSNumber *errorCode;
@property(nonatomic,retain) NSString *errorDescription;
@end