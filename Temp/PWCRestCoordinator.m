//
//  PWCRestCoordinator.m
//  PlanwellCollaboration
//
//  Created by Abhijit Mukherjee on 05/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PWCRestCoordinator.h"
#import "QWatchedOperationQueue.h"
#import "PageOperation.h"
#import "QEntityMapper.h"
#import "PWCEntityMapping.h"
#import "PWCAppDelegate.h"
#import "PWCEntity.h"
#import "PWCResourceStream.h"
#import "PWCCoreDataHelper.h"

#define MAX_OPERATIONS_CONCURRENTLY 2
#define PROCESS_ID  @"ProcessID"
#define TIME_SPAN  @"TS"
#define CONVERSION_STATUS @"ConversionStatus"
#define RETRY_COUNT 3
#define APPLICATION_DATA_DIRECTORY @"Application Data"

@interface PWCRestCoordinator ()  {
    Class _callingClass;
}

// Read/write versions of public properties
@property (nonatomic, copy, readwrite) NSError *error;

@property (retain, readwrite ) NSThread * targetThread;

//- (void)startMonitoring;
//- (void)stop;
//- (BOOL)operationDidStart:(id)op completionHandler:(CompletionCallbackBlock)handler;
//- (const void *)operationDidFinish:(id)op;

/*- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping completionHandler:(CompletionCallbackBlock)handler;
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping completionHandler:(CompletionCallbackBlock)handler;
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler;
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream completionHandler:(CompletionCallbackBlock)handler;
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream fileName:(NSString *)fileName toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler;
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream fileName:(NSString *)fileName completionHandler:(CompletionCallbackBlock)handler intermediate:(IntermediateCallbackBlock)intermediateCallBack;
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream  fileName:(NSString *)fileName toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler intermediate:(IntermediateCallbackBlock)intermediateCallBack;
- (id)downloadResource:(NSString *)newUrlString forProcess:(NSString *)processID toLocalPath:(NSString *)savePath retryCount:(NSInteger)retry calledAfter:(NSString *)delay completionHandler:(CompletionCallbackBlock)handler;
- (id)startRequest:(NSURLRequest*)request forProcess:(NSString *)processID onlyResourceStream:(BOOL)isResourceStream  fileName:(NSString *)fileName toLocalPath:(NSString *)savePath retryCount:(NSInteger)retry calledAfter:(NSString *)delay completionHandler:(CompletionCallbackBlock)handler ;*/

+ (NSMutableURLRequest*)prepareRequestFromUrl:(NSString*)urlString withHeader:(NSDictionary*)headerFields withBody:(NSString*)body;
+ (NSMutableURLRequest*)prepareRequestFromUrl:(NSString*)destinationPath fileName:(NSString*)filePath withHeader:(NSDictionary*)headerFields andBody:(NSData*)srcBody;

+ (void)addObjectMapping:(PWCEntityMapping *)objectMapping context:(PWCObjectMappingProviderContext)context;
+ (id)valueForContext:(PWCObjectMappingProviderContext)context;

//- (void)addOperation:(id)op ToQ:(QWatchedOperationQueue*)targetQ createNewThread:(BOOL)newThread;
//- (void)startOperationsFromQueue:(QWatchedOperationQueue*)targetQ createNewThread:(BOOL)newThread;

@end

@implementation PWCRestCoordinator
@synthesize targetThread = _targetThread;
@synthesize mapperQueue = _mapperQueue;
@synthesize error = _error;
@synthesize mappingProvider = _mappingProvider;
/*
@synthesize reachable;
@synthesize reachableViaWiFi;
@synthesize networkReachability = _networkReachability;
*/

#pragma mark - Singleton implementation
// minimum static method
static PWCRestCoordinator *sharedCoordinator = nil;

+ (id)restManager {
    @synchronized(self) {
        if(sharedCoordinator == nil)
            sharedCoordinator = [[super allocWithZone:NULL] init];
    }
    return sharedCoordinator;
}

- (id)init{
    
    self = [super init];
    if(nil != self){
        _operationToCompletionAction = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
        _mapperQueue = [[QWatchedOperationQueue alloc] initWithTarget:self];//SMB:
        self.targetThread = [NSThread currentThread];//SMB:
        _mappingProvider = [[NSMutableDictionary alloc] init];
        /*
        self.networkReachability = [Reachability reachabilityForInternetConnection];
        [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            Reachability* curReach = [note object];
            NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
            [self reachabiltyChangedWithNewReachabilty:curReach];
        }];
        [self reachabiltyChangedWithNewReachabilty:self.networkReachability];
         */
    }
    
    return self;
}

// IMPORTANT: runningOperationCount is only ever modified by the main thread,
// so we don't have to do any locking.  Also, because the 'done' methods are called
// on the main thread, we don't have to worry about early completion, that is,
// -parseDone: kicking off download 1, then getting delayed, then download 1
// completing, decrementing runningOperationCount, and deciding that we're
// all done.  The decrement of runningOperationCount is done by -downloadDone:
// and -downloadDone: can't run until we return back to the run loop.


/*- (void)operationDidStart
// Called when an operation has started to increment runningOperationCount.
{
    self.runningOperationCount += 1;
    if (self.runningOperationCount == 1) {
        self.done = NO;
    }
//    if (self.operatingQueue && self.operatingQueue == self.heavyQueue) {
//        resourceOperationCount++;
//    }
//    if (self.heavyResourceQueue.operationCount == 1 && !monitorEnable) {
//        monitorEnable = YES;
//        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:monitorEnable]];
//    }

    
    //self.inIterationCounter += 1;
}

- (BOOL)operationDidStart:(id)op completionHandler:(CompletionCallbackBlock)handler{
    NSAssert([NSThread isMainThread],@"Attempt to add to operatiOnCompletion dictionary from other thread");
    assert(op != nil);
    //    assert(handler != NULL);
    // Add the operation-to-action map entry.  We do this synchronised
    // because we can be running on any thread.
    BOOL addedHandlerForNewOperation = YES;
    @synchronized (self)
    {
        if (handler!= NULL) {
            
            
            //        NSString *key = [op rootKeyPath] ? [op rootKeyPath] : NSStringFromClass([op objectClass]);
            NSString *key = [NSString stringWithFormat:@"%u" ,[op hash]];
            if(! CFDictionaryContainsKey(self->_operationToCompletionAction, (const void*) key)){
                CFDictionarySetValue(self->_operationToCompletionAction, (const void *)key , (const void *) Block_copy(handler));
                [self operationDidStart];
            } else
                addedHandlerForNewOperation = NO;
        }
    }
    return addedHandlerForNewOperation;
}

- (void)operationDidFinish{
    
    self.runningOperationCount -= 1;
    if (self.runningOperationCount == 0) {
        self.done = YES;
    }
}

- (const void *)operationDidFinish:(id)op
// Called when an operation has finished to decrement runningOperationCount
// and complete the whole fetch if it hits zero.
{
    NSAssert([NSThread isMainThread],@"Attempt to retrieve from operatiOnCompletion dictionary from other thread");
    assert(self.runningOperationCount != 0);
    assert([op isFinished]);
    
    // Pull the action out of the operation-to-action map, remembering the
    // action that was required.
    CompletionCallbackBlock action;
    //    @synchronized (self) {
    //        NSString *key = [op rootKeyPath]? [op rootKeyPath] : NSStringFromClass([op objectClass]);
    NSString *key = [NSString stringWithFormat:@"%u" ,[op hash]];
    assert( CFDictionaryContainsKey(self->_operationToCompletionAction, (const void *) key) );
    action = (CompletionCallbackBlock) CFDictionaryGetValue(self->_operationToCompletionAction, (const void *) key);
    CFDictionaryRemoveValue(self->_operationToCompletionAction, (const void *) key);
    [_streamDict removeObjectForKey:((PageOperation *)op).operationId];
    assert(action != nil);
    //    }
    
    [self operationDidFinish];
    NSLog(@"HEAVY OPERATION COUNT : %d",(self.downloadQueue.operationCount + self.uploadQueue.operationCount));
    NSLog(@"TOTAL OPERATION COUNT : %d",(self.downloadOperationHoldingArray.count + self.uploadOperationHoldingArray.count));
    if ([op isKindOfClass:[PageOperation class]]) {
        if (self.uploadQueue.operationCount == 0 && [[self downloadOperationHoldingArray] count] == 0 && [[self uploadOperationHoldingArray] count] == 0 && monitorEnable && [op isResourceStream]) {
            monitorEnable = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:monitorEnable]];
        }
    }
    
    return action;
}

#pragma mark - Queue getters, Lazy loads

- (QWatchedOperationQueue *) globalQueue
{
    if (self->_globalQueue == nil) {
        self->_globalQueue = [[QWatchedOperationQueue alloc] initWithTarget:self];
        assert(self->_globalQueue != nil);
    }
    return self->_globalQueue;
}

 #pragma mark - Thread dispatch

- (QWatchedOperationQueue *) downloadQueue
{
    if (self->_downloadQueue == nil) {
        self->_downloadQueue = [[QWatchedOperationQueue alloc] initWithTarget:self];
        //[self->_heavyResourceQueue setMaxConcurrentOperationCount:self.maxConcurrentHeavyOperations];
        assert(self->_downloadQueue != nil);
    }
    return self->_downloadQueue;
}

- (QWatchedOperationQueue *) uploadQueue
{
    if (self->_uploadQueue == nil) {
        self->_uploadQueue = [[QWatchedOperationQueue alloc] initWithTarget:self];
        //[self->_heavyResourceQueue setMaxConcurrentOperationCount:self.maxConcurrentHeavyOperations];
        assert(self->_uploadQueue != nil);
    }
    return self->_uploadQueue;
}

#pragma mark - Thread dispatch

- (void)startMonitoring {
    NSAutoreleasePool *monitorThreadPool = [[NSAutoreleasePool alloc] init];
    //When the first operation is about to start
    if (1 == self.runningOperationCount) {
        self.targetThread = [NSThread currentThread];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
   
        do {
            @try {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
            @catch (NSException *exception) {
                NSLog(@"EXCEPTION OCCURED : %@",exception.reason);
            }
            @finally {
                ;
            }
        } while ( ! _done );
        self.targetThread = nil;
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (self->_callingClass) {
            _callingClass = NULL;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveActivityIndicator" object:nil];
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    [monitorThreadPool drain];
}*/

+ (void)setCallingClass:(Class)callingClass {
    PWCRestCoordinator *restCordinator = [PWCRestCoordinator restManager];
    restCordinator->_callingClass = callingClass;
}


/*- (void)stopWithError:(NSError *)error
// An internal method called to stop the fetch and clean things up.
{
    assert(error != nil);
    NSLog(@"%@",[error userInfo]);
    [self.globalQueue invalidate];
    //[self.lightQueue cancelAllOperations];
    [PWCRestCoordinator cancelAllOperations];
    [self->_globalQueue release];
    self->_globalQueue = nil;
    self.error = error;
    self.done = YES;
}

- (void)stop
// See comment in header.
{
    [self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}*/

/*
#pragma mark - DataManager AI

- (void) reachabiltyChangedWithNewReachabilty:(Reachability *) newReachabilty {
    if (newReachabilty == self.networkReachability){
        NetworkStatus netStatus = [newReachabilty currentReachabilityStatus];
        switch (netStatus) {
            case NotReachable: {
                self.reachable = NO;
                self.reachableViaWiFi = NO;
            }
                break;
            case  ReachableViaWWAN: {
                self.reachable = YES;
                self.reachableViaWiFi = NO;
            }
                break;
            case ReachableViaWiFi: {
                self.reachable = YES;
                self.reachableViaWiFi = YES;
            }
                break;
            default: {
                self.reachable = NO;
                self.reachableViaWiFi = NO;
            }
                break;
        }
    }
    [self.networkReachability stopNotifier];
    [self.networkReachability startNotifier];
    [self updateDataPathAccordingReachabilty];
}

- (void) updateDataPathAccordingReachabilty {
    //write ai for choosing the data path either cloud or local
}
*/


#pragma mark - Utility methods

+ (NSString *)_generateUUIDString
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
    result = (NSString *)uuidStr;
    
    // transfer ownership of the string
    // to the autorelease pool
    [result autorelease];
    
    // release the UUID
    CFRelease(uuid);
    
    //    CFRelease(uuidStr);
    
    return result;
}

+ (NSString *)tempDirectoryPath
// Returns the path to the caches directory.  This is a class method because it's
// used by +applicationStartup.
{
    NSString *      result;
    /*NSArray *       paths;
    result = nil;
    paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ( (paths != nil) && ([paths count] != 0) ) {
        assert([[paths objectAtIndex:0] isKindOfClass:[NSString class]]);
        result = [paths objectAtIndex:0];
    }*/
    result = [NSTemporaryDirectory()/*result*/ stringByAppendingPathComponent:APPLICATION_DATA_DIRECTORY];
    if (![[NSFileManager defaultManager] fileExistsAtPath:result]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:result withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return result;
}

+ (NSString *)cachesDirectoryPath {
    NSString *result;
    NSArray *paths;
     
    result = nil;
    paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ((paths != nil) && ([paths count] != 0)) {
        assert([[paths objectAtIndex:0] isKindOfClass:[NSString class]]);
        result = [paths objectAtIndex:0];
    }
    result = [result stringByAppendingPathComponent:APPLICATION_DATA_DIRECTORY];
    if (![[NSFileManager defaultManager] fileExistsAtPath:result]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:result withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return result;
}
#pragma mark - Mapping methods, Removing Mappings

- (void)addResponseHandler:(CompletionCallbackBlock)block forKey:(NSString*)dicKey{
    
    if(! CFDictionaryContainsKey(self->_operationToCompletionAction, (const void*) dicKey)){
        CFDictionarySetValue(self->_operationToCompletionAction, (const void *)dicKey , (const void *) Block_copy(block));
    }
    else {
        CFDictionaryReplaceValue(self->_operationToCompletionAction, (const void *)dicKey , (const void *) Block_copy(block));
    }
}

- (void)removeResponseHandlerForKey:(NSString*)dicKey {
    CompletionCallbackBlock action = (CompletionCallbackBlock) CFDictionaryGetValue(self->_operationToCompletionAction, (const void *) dicKey);
    CFDictionaryRemoveValue(self->_operationToCompletionAction, (const void *) dicKey);
    Block_release(action);
}

- (CompletionCallbackBlock)responseHandlerForKey:(NSString*)dicKey {
    return (CompletionCallbackBlock) CFDictionaryGetValue(self->_operationToCompletionAction, (const void *) dicKey);
}

static void remKeys (const void* key, const void* value, void* context) {
    Block_release(value);
}

- (void)removeAllResponseHandler {
    
    CFDictionaryApplyFunction(self->_operationToCompletionAction, remKeys, NULL);
    CFDictionaryRemoveAllValues(self->_operationToCompletionAction);
}

#pragma mark - Mapping methods, Adding Mappings & Removing Mappings

+ (void)addObjectMapping:(PWCEntityMapping *)objectMapping{
    [self addObjectMapping:objectMapping context:PWCObjectMappingProviderContextObjectsByType];
}

+ (void)addObjectMapping:(PWCEntityMapping *)objectMapping context:(PWCObjectMappingProviderContext)context{
    
    NSNumber *key = [NSNumber numberWithInt:context];
    
    NSMutableDictionary *mapppings = [[self restManager] mappingProvider];
    
    NSMutableArray *contextValue = [mapppings objectForKey:key];
    if (contextValue == nil) {
        contextValue = [NSMutableArray arrayWithCapacity:1];
        [mapppings setObject:contextValue forKey:key];
    }
    [contextValue addObject:objectMapping];
}

/*
 Save each mapping in the mapping provider so that later they can be supplied to the operation
 that requires it for creating instances
 */
+ (void)setMapping:(PWCEntityMapping *)mapping forKeyPath:(NSString *)keyPath context:(PWCObjectMappingProviderContext)context {
    
    NSNumber *key = [NSNumber numberWithInt:context];
    NSMutableDictionary *mapppings = [[self restManager] mappingProvider];
    
    NSMutableDictionary *contextValue = [self valueForContext:context];
    if (contextValue == nil) {
        contextValue = [NSMutableDictionary dictionary];
        [mapppings setObject:contextValue forKey:key];
    }
    [contextValue setValue:mapping forKey:keyPath];
}

+ (void)setMapping:(PWCEntityMapping*)mapping forKeyPath:(NSString*)keyPath{
    [self setMapping:mapping forKeyPath:keyPath context:PWCObjectMappingProviderContextObjectsByKeyPath];
}

#pragma mark - Retrieveing mappings

+ (id)valueForContext:(PWCObjectMappingProviderContext)context {
    NSMutableDictionary *mapppingProviders = [[self restManager] mappingProvider];
    NSNumber *contextNumber = [NSNumber numberWithInteger:context];
    return [mapppingProviders objectForKey:contextNumber];
}


+ (PWCEntityMapping *)mappingForKeyPath:(NSString *)keyPath context:(PWCObjectMappingProviderContext)context {
    NSMutableDictionary *contextValue = [self valueForContext:context];
    //    NSAssert(contextValue, @"Attempted to retrieve mapping from undefined context: %d", context);
    return [contextValue valueForKey:keyPath];
}

+ (PWCEntityMapping*)mappingForKeyPath:(NSString*)keyPath{
    return [self mappingForKeyPath:keyPath context:PWCObjectMappingProviderContextObjectsByKeyPath];
}

+ (NSArray *)objectMappingsForClass:(Class)theClass {
    NSMutableArray *mappings = [NSMutableArray array];
    NSArray *mappingByType = [self valueForContext:PWCObjectMappingProviderContextObjectsByType];
    NSArray *mappingByKeyPath = [[self valueForContext:PWCObjectMappingProviderContextObjectsByKeyPath] allValues];
    NSArray *mappingsToSearch = nil;
    if ([mappingByKeyPath count] > 0) {
        mappingsToSearch = [[NSArray arrayWithArray:mappingByType] arrayByAddingObjectsFromArray:mappingByKeyPath];
    } else {
        mappingsToSearch = [NSArray arrayWithArray:mappingByType];
    }
    for (PWCEntityMapping *candidateMapping in mappingsToSearch) {
        if ( ![candidateMapping respondsToSelector:@selector(objectClass)] || [mappings containsObject:candidateMapping])
            continue;
        Class mappedClass = [candidateMapping performSelector:@selector(objectClass)];
        if (mappedClass && [NSStringFromClass(mappedClass) isEqualToString:NSStringFromClass(theClass)]) {
            [mappings addObject:candidateMapping];
        }
    }
    return [NSArray arrayWithArray:mappings];
}

+ (PWCEntityMapping *)objectMappingForClass:(Class)theClass {
    NSArray* objectMappings = [self objectMappingsForClass:theClass];
    return ([objectMappings count] > 0) ? [objectMappings objectAtIndex:0] : nil;
}

#pragma mark - Request Preparation methods

+ (NSMutableURLRequest*)prepareRequestFromUrl:(NSString*)urlString withHeader:(NSDictionary*)headerFields{
    
    NSMutableURLRequest *mreq = nil;
    mreq = [[[NSMutableURLRequest alloc] init] autorelease];
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[mreq setURL:[NSURL URLWithString:urlString]];
    [mreq setTimeoutInterval:241.0f];
    if (headerFields)
        [mreq setAllHTTPHeaderFields:headerFields];
    
    return mreq;
}

+ (NSMutableURLRequest*)prepareRequestFromUrl:(NSString*)urlString withHeader:(NSDictionary*)headerFields withBody:(NSString*)body{
    
    NSMutableURLRequest *mreq = [self prepareRequestFromUrl:urlString withHeader:headerFields];
    if (body) {
        NSData *postData = [body dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
        
        [mreq setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [mreq setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [mreq setHTTPBody:postData];
    }
    return mreq;
}

+ (NSMutableURLRequest*)prepareRequestFromUrl:(NSString*)destinationPath fileName:(NSString*)filePath withHeader:(NSDictionary*)headerFields andBody:(NSData*)srcBody{
    
  
    NSString *              boundaryStr = @"--0xKhTmLbOuNdArY";
    
    
    NSMutableData *body = [NSMutableData data];
    
    NSString *contentType = nil;
    NSString *checkExt = [filePath.pathExtension lowercaseString];
    if ( [checkExt isEqual:@"png"] ) {
        contentType = @"image/png";
    } else if ( [checkExt isEqual:@"jpg"] ) {
        contentType = @"image/jpeg";
    } else if ( [checkExt isEqual:@"gif"] ) {
        contentType = @"image/gif";
    } else {
        contentType = @"application/octet-stream";          // quieten a warning
    }
    // Calculate the multipart/form-data body.  For more information about the
    // format of the prefix and suffix, see:
    //
    // o HTML 4.01 Specification
    //   Forms
    //   <http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4>
    //
    // o RFC 2388 "Returning Values from Forms: multipart/form-data"
    //   <http://www.ietf.org/rfc/rfc2388.txt>
    
    //Dont require, simply raw bytes would do
    NSString *bodyPrefixStr = [NSString stringWithFormat:
                               @
                               // empty preamble
                               "\r\n"
                               "--%@\r\n"
                               "Content-Disposition: form-data; name=\"fileContents\"; filename=\"%@\"\r\n"
                               //                     "Content-Type: application/octet-stream\r\n"
                               "Content-Type: %@\r\n"
                               "\r\n",
                               boundaryStr,
                               [filePath lastPathComponent],       // +++ very broken for non-ASCII
                               contentType
                               ];
    
    NSString *bodySuffixStr = [NSString stringWithFormat:
                               @
                               "\r\n"
                               "--%@--\r\n"
                               //empty epilogue
                               ,
                               boundaryStr
                               ];
    
    
    NSData *bodyPrefixData = [bodyPrefixStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *bodySuffixData = [bodySuffixStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger bodyLength = [bodyPrefixData length] + [srcBody length] + [bodySuffixData length];//[srcBody length];//
    
    
    [body appendData:bodyPrefixData];
    [body appendData:srcBody];
    [body appendData: bodySuffixData];
    
    /*
     NSString *uploadURL = [NSString stringWithFormat:@"http://staging1.planwellcollaborate.com/pwcollaborate/HttpMultiPartUploadHandler2.ashx?file=%@&offset=&last=true&first=true&param=&fileGuid=%@&location=CommandType=1.2.2.1~ProjectID=12212~FolderID=12356~UserID=12254&size=%d&title=&desc=&searchtags=&OnDuplicateAction=0&source=16",[filePath lastPathComponent],[self _generateUUIDString],bodyLength];
     */

    NSMutableURLRequest *mreq = [self prepareRequestFromUrl:destinationPath withHeader:nil];
    
    [mreq setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryStr] forHTTPHeaderField:@"Content-Type"];
    //[mreq setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [mreq setValue:[NSString stringWithFormat:@"%llu", (unsigned long long) bodyLength] forHTTPHeaderField:@"Content-Length"];
    [mreq setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    [mreq setHTTPBody:body];
    
    return mreq;
    
}

- (void)rescheduleOperation:(PWCDownloadRequestOperation *)operation withHandler:(CompletionCallbackBlock)handler {
    
    NSUInteger rcount = operation.retryCount+1;
    NSString *tpath = operation.targetPath;
    
    NSDictionary *headerResponse = operation.response.allHeaderFields;

    NSString *processID = [headerResponse valueForKey:PROCESS_ID];
    NSString *delay = [headerResponse valueForKey:TIME_SPAN];
    NSString *opid = operation.operationId;
    
    if ([delay intValue] == 0) delay = DEFAULT_TS;
    
    NSString *newURL = [operation.response.URL absoluteString];
    
    if (rcount <= 1) {
        newURL = [newURL stringByAppendingFormat:@"&%@=%@&%@=%@", PROCESS_ID, processID, TIME_SPAN, delay];
    } else {
        newURL = [self updatedURLString:newURL WithDelay:delay];
    }
    
    double delayInSeconds = [delay doubleValue];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self responseHandlerForKey:opid]!=NULL) { //do not perform new connection if it is canceled
            [[self class] downloadResource:newURL toLocalPath:tpath completionHandler:handler retryCount:rcount];
        }
    });
    
    [self addResponseHandler:handler forKey:opid];//add the operation response handler
}

#pragma mark - POST Requests

+ (id)postRequest:(NSString*)urlString withHeader:(NSDictionary*)header allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler{
    return [self  postRequest:urlString withModelMapping:nil withHeader:header andBody:nil allowMapping:allowMapping completionHandler:handler];
}

+ (id)postRequest:(NSString*)urlString withHeader:(NSDictionary*)header completionHandler:(CompletionCallbackBlock)handler{
    return [self postRequest:urlString withModelMapping:nil withHeader:header andBody:nil  completionHandler:handler];
}

+ (id)postRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header andBody:(NSString*)body completionHandler:(CompletionCallbackBlock)handler{
    return [self  postRequest:urlString withModelMapping:mapping withHeader:header andBody:body allowMapping:YES completionHandler:handler];
}


+ (id)postRequest:(NSString*)urlString withHeader:(NSDictionary*)header andBody:(NSString*)body completionHandler:(CompletionCallbackBlock)handler{
    return [self  postRequest:urlString withModelMapping:nil withHeader:header andBody:body allowMapping:NO completionHandler:handler];
}

+ (id)postRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)model withHeader:(NSDictionary*)header andBody:(NSString*)body allowMapping:(BOOL)mapping completionHandler:(CompletionCallbackBlock)handler {
    NSMutableURLRequest *mreq = [[self class] prepareRequestFromUrl:urlString withHeader:header withBody:body];
    [mreq setHTTPMethod:@"POST"];
    return [[self restManager] startRequest:mreq withModelMapping:model withHeader:header andBody:body allowMapping:mapping completionHandler:handler];
}



#pragma mark - GET Requests

+ (id)getRequest:(NSString*)urlString withHeader:(NSDictionary*)header allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler{
    return [self  getRequest:urlString withModelMapping:nil withHeader:header allowMapping:allowMapping completionHandler:handler];
    
}

+ (id)getRequest:(NSString*)urlString withHeader:(NSDictionary*)header completionHandler:(CompletionCallbackBlock)handler{
    return [self  getRequest:urlString withModelMapping:nil withHeader:header allowMapping:YES completionHandler:handler];
    
}

+ (id)getRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header completionHandler:(CompletionCallbackBlock)handler{
    return [self  getRequest:urlString withModelMapping:mapping withHeader:header allowMapping:YES completionHandler:handler ];
}

+ (id)getRequest:(NSString*)urlString withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header  allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler {
    
    //SMB:
    
    NSMutableURLRequest *mreq = [[self class] prepareRequestFromUrl:urlString withHeader:header];
    [mreq setHTTPMethod:@"GET"];
    
    return [[self restManager] startRequest:mreq withModelMapping:mapping withHeader:header andBody:nil allowMapping:allowMapping completionHandler:handler];
    
    /*return [[PWCHTTPClient sharedClient] sendRequest:mreq withMapping:mapping allowMapping:allowMapping success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error.code==NSURLErrorCancelled) {
            //handle gracefully when cancelled operation returns callback ...
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"OperationCancelled", nil), NSLocalizedDescriptionKey,nil];
            NSError *cancellationError = [NSError errorWithDomain:PWCLocalErrorDomain code:CancelErrorCode userInfo:userInfo];
            handler(NO,cancellationError);
        }
        else if (operation.error != nil) {
            if(operation.responseData && [operation.error code] > 0){
                QEntityMapper *mapper = [[QEntityMapper alloc] initWithData:operation.responseData forError:YES];
                [mapper setObjectMapping:[PWCError entityMapping]];
                if(operation.rootKeyPath)
                    mapper.rootKeyPath = operation.rootKeyPath;
                mapper.operationId = operation.operationId;
                mapper.hashValue = operation.hash;
                mapper.statusCode = [operation.response statusCode];
                [self.mapperQueue addOperation:mapper finishedAction:@selector(mappingDone:)];
                [mapper release];
            }
            else{
                handler(NO,operation.error);
                return;
            }
        }
        else {
            if([operation allowMapping]){
                NSError *error = nil;
                QEntityMapper *mapper = [[QEntityMapper alloc] initWithData:operation.responseData response:operation.response];
                if (operation.rootKeyPath) {
                    mapper.objectMapping = [[self class] mappingForKeyPath:operation.rootKeyPath];
                    mapper.rootKeyPath = operation.rootKeyPath;
                }
                else {
                    mapper.objectMapping = [[self class] objectMappingForClass:operation.objectClass];
                }
                mapper.hashValue = operation.hash;
                mapper.operationId = operation.operationId;
                [self.mapperQueue addOperation:mapper finishedAction:@selector(mappingDone:)];
                [mapper release];
            }
            
        }
        
    }];*/

    
    //return [[PWCRestCoordinator restManager] startRequest:mreq withMapping:mapping allowMapping:allowMapping completionHandler:handler ];
}

#pragma mark - Start REST Request


- (id)startRequest:(NSMutableURLRequest*)mreq withModelMapping:(PWCEntityMapping*)mapping withHeader:(NSDictionary*)header andBody:(NSString*)body  allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler{
    
    //SMB:
    
    id opID = [[PWCHTTPClient sharedClient] sendRequest:mreq withMapping:mapping allowMapping:allowMapping success:^(PWCHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"REST RESPONSE");
        if([operation allowMapping]){
            
            NSString *key = [NSString stringWithFormat:@"%u" ,[operation hash]];
            if(! CFDictionaryContainsKey(self->_operationToCompletionAction, (const void*) key)){
                CFDictionarySetValue(self->_operationToCompletionAction, (const void *)key , (const void *) Block_copy(handler));
            }
            
            QEntityMapper *mapper = [[QEntityMapper alloc] initWithData:operation.responseData response:operation.response];
            if (operation.rootKeyPath) {
                mapper.objectMapping = [[self class] mappingForKeyPath:operation.rootKeyPath];
                mapper.rootKeyPath = operation.rootKeyPath;
            }
            else {
                mapper.objectMapping = [[self class] objectMappingForClass:operation.objectClass];
            }
            mapper.hashValue = operation.hash;
            mapper.operationId = operation.operationId;
            [self.mapperQueue addOperation:mapper finishedAction:@selector(mappingDone:)];
            [mapper release];
        }
        else {
            handler(operation.error == nil, operation.response);
        }
        
    } failure:^(PWCHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"REST ERROR: %@",error);
        if (error.code==NSURLErrorCancelled) {
            //handle gracefully when cancelled operation returns callback ...
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"OperationCancelled", nil), NSLocalizedDescriptionKey,nil];
            NSError *cancellationError = [NSError errorWithDomain:PWCLocalErrorDomain code:CancelErrorCode userInfo:userInfo];
            handler(NO,cancellationError);
        }
        else {
            if(operation.responseData || [operation.error code] > 0){
                NSLog(@"ZZZZZ!");
                NSString *key = [NSString stringWithFormat:@"%u" ,[operation hash]];
                if(! CFDictionaryContainsKey(self->_operationToCompletionAction, (const void*) key)){
                    CFDictionarySetValue(self->_operationToCompletionAction, (const void *)key , (const void *) Block_copy(handler));
                }
                
                QEntityMapper *mapper = [[QEntityMapper alloc] initWithData:operation.responseData forError:YES];
                [mapper setObjectMapping:[PWCError entityMapping]];
                if(operation.rootKeyPath)
                    mapper.rootKeyPath = operation.rootKeyPath;
                mapper.operationId = operation.operationId;
                mapper.hashValue = operation.hash;
                mapper.statusCode = [operation.response statusCode];
                [self.mapperQueue addOperation:mapper finishedAction:@selector(mappingDone:)];
                [mapper release];
            }
            else{
                handler(NO,operation.error);
                return;
            }
        }
        
        
    }];
    
    //return [[PWCRestCoordinator restManager] startRequest:mreq withMapping:mapping allowMapping:allowMapping completionHandler:handler ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opID];
    
    return opID;
}

#pragma mark - Upload/Download files

/*+ (id)downloadResource:(NSString*)urlString completionHandler:(CompletionCallbackBlock)handler{
    
    //SMB:
    //NSMutableURLRequest *mreq = [self prepareRequestFromUrl:urlString withHeader:nil];
    //[mreq setHTTPMethod:@"GET"];
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [[PWCHTTPClient sharedClient] downloadFile:urlString parameters:nil localPath:@"" success:^(AFDownloadRequestOperation *operation, id responseObject) {
        
    } failure:^(AFDownloadRequestOperation *operation, NSError *error) {
        
    } progressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        
    }];
    
    //return [[PWCRestCoordinator restManager] startRequest:mreq withMapping:nil allowMapping:NO onlyResourceStream:YES completionHandler:handler];
}*/

//Sayan
+ (id)downloadResource:(NSString*)urlString toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler{
    
    return [self downloadResource:urlString toLocalPath:savePath completionHandler:handler retryCount:0];
}


+ (id)downloadResource:(NSString*)urlString toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler retryCount:(NSUInteger)rcount {
    /*NSMutableURLRequest *mreq = [self prepareRequestFromUrl:urlString withHeader:nil];
     [mreq setHTTPMethod:@"GET"];
     return [[PWCRestCoordinator restManager] startRequest:mreq withMapping:nil allowMapping:NO onlyResourceStream:YES fileName:[savePath lastPathComponent] toLocalPath:savePath completionHandler:handler];*/
    
    //SMB:
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    
    id opID =  [[PWCHTTPClient sharedClient] downloadFile:urlString parameters:nil localPath:savePath success:^(PWCDownloadRequestOperation *operation, id responseObject) {
        
        NSLog(@"DOWNLOAD RESPONSE:%@",operation.responseString);
   
        if ((operation.conversionStatus!= ConversionDone) && (operation.conversionStatus <= ConversionFailed)) {
            if ( rcount<=2) {
                //canceled as conversion is not done
                NSLog(@"Download Operation will retry");
                operation.retryCount = rcount;
                [[self restManager] rescheduleOperation:operation withHandler:handler];
            }
            else {
                PWCError *serverError = [[PWCError alloc] init];
                serverError.errorCode = [NSNumber numberWithInt:ConversionFailed];
                serverError.errorDescription = @"";
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:serverError,NSLocalizedFailureReasonErrorKey, nil];
                NSError *errorObj = [NSError errorWithDomain:PWCServerErrorDomain code:RetryCountExceededCode userInfo:userInfo];
                [serverError release];
                
                handler(NO,errorObj);
            }
        }
        else
        {
            NSNumber *finalDocId = nil;
            NSString *responseString = nil;
            NSError *error = nil;
            
            responseString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:operation.targetPath options:NSDataReadingMappedIfSafe error:&error] encoding:NSUTF8StringEncoding];
            
            NSSet *contentSet = [[NSSet alloc] initWithObjects:@"text/plain", nil];
            NSString *contentType = [operation.response MIMEType];
            BOOL checkResponseString  = ![contentSet containsObject:contentType];
            [contentSet release];
            NSDictionary *result = nil;
            NSError *errorObj = nil;
            if(responseString && checkResponseString) {
                NSArray *parts = [responseString componentsSeparatedByString:@";"];
                if ([parts count] > 1) {
                    NSString *docId = [parts objectAtIndex:1];
                    NSArray *docPart = [docId componentsSeparatedByString:@"^"];
                    if(docPart.count > 1){
                        long longDocValue = [[docPart objectAtIndex:1] longLongValue];
                        if(longDocValue >= 0)
                            finalDocId = [NSNumber numberWithLong:longDocValue];
                        else{
                            NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"^:"];
                            NSString *status = [parts objectAtIndex:0];
                            NSRange rangeStatus = [status rangeOfCharacterFromSet:cset];
                            NSInteger statusCode = [[status substringFromIndex:rangeStatus.location + 1] integerValue];
                            
                            NSString *description = @"Upload error";
                            NSLog(@"Check response string in operationDone method, some problem with it");
                            if ([parts count] > 2) {
                                description = [parts objectAtIndex:2];
                                NSRange rangeDesc = [description rangeOfCharacterFromSet:cset];
                                description = [description substringFromIndex:rangeDesc.location + 1];
                            }
                            
                            PWCError *serverError = [[PWCError alloc] init];
                            serverError.errorCode = [NSNumber numberWithInt:statusCode];
                            serverError.errorDescription = description;
                            
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:serverError,NSLocalizedFailureReasonErrorKey, nil];
                            errorObj = [NSError errorWithDomain:PWCServerErrorDomain code:statusCode userInfo:userInfo];
                            [serverError release];
                        }
                    }
                }
                
                if (finalDocId){
                    result = [NSDictionary dictionaryWithObject:finalDocId forKey:kTargetEntity];
                    handler (YES,result);
                } else
                    handler (NO,errorObj);
                
                [responseString release];
            }
            else{
                result = [NSDictionary dictionaryWithObjectsAndKeys:operation.response.allHeaderFields,kResponseHeaderEntity,operation.targetPath,kTargetEntity, nil];
                if (responseString) {
                    [responseString release];
                }
                handler (YES,result);
            }
        }
        
    } failure:^(PWCDownloadRequestOperation *operation, NSError *error) {
        NSLog(@"DOWNLOAD ERROR:%@",error);
        /*if ([error code]==NSURLErrorCancelled && rcount<=2) {
            //canceled as conversion is not done
            NSLog(@"Download Operation Canceled Forcefully");
            operation.retryCount = rcount;
            [[self restManager] rescheduleOperation:operation withHandler:handler];
        }
        else {*/
            handler(NO, error);
        //}
    } progressBlock:^(PWCDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        
        //----Calculate the Progress------//
        operation.dataTransferProgress = (float)totalBytesRead/ (float)totalBytesExpectedToReadForFile;
        
        //----Calculate the time lapsed----//
        /*NSDate *newTimeStamp = [NSDate date];
         NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
         NSDateComponents *components = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:operation.timeStamp toDate:newTimeStamp options:0];
         float timeGap = [components hour] * 3600 + [components minute] * 60 + [components second];
         operation.timeLapsed += timeGap;*/
        //---------------------------------//
        
        
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opID];
    
    return opID;
}

/*- (id)downloadResource:(NSString *)newUrlString forProcess:(NSString *)processID toLocalPath:(NSString *)savePath retryCount:(NSInteger)retry calledAfter:(NSString *)delay completionHandler:(CompletionCallbackBlock)handler {
    NSMutableURLRequest *mreq = [[self class] prepareRequestFromUrl:newUrlString withHeader:nil];
    [mreq setHTTPMethod:@"POST"];
    return [[PWCRestCoordinator restManager] startRequest:mreq forProcess:processID onlyResourceStream:YES fileName:[savePath lastPathComponent] toLocalPath:savePath retryCount:retry calledAfter:delay completionHandler:handler];
}*/


+ (id)uploadRequest:(NSString*)uploadUrlString fileName:(NSString*)fileName withHeader:(NSDictionary*)header andBody:(NSData*)fileData completionHandler:(CompletionCallbackBlock)handler{
    return [self uploadRequest:uploadUrlString fileName:fileName withHeader:header andBody:fileData completionHandler:handler intermediate:NULL];
}

+ (id)uploadRequest:(NSString*)uploadUrlString fileName:(NSString*)fileName withHeader:(NSDictionary*)header andBody:(NSData*)fileData completionHandler:(CompletionCallbackBlock)handler intermediate:(IntermediateCallbackBlock)intermediateCallback {
    
//SMB:
    /*PWCResourceStream *stream  =[[PWCResourceStream alloc] init];
    NSMutableURLRequest *mreq = [[self class] prepareRequestFromUrl:uploadUrlString withHeader:header];
    [stream addStreamTo:mreq fileName:fileName andBody:fileData] ;
    //[self prepareRequestFromUrl:uploadUrlString fileName:fileName withHeader:header andBody:fileData];
    [mreq setHTTPMethod:@"POST"];
    //    [stream release];
    id operationID =  [[PWCRestCoordinator restManager] startRequest:mreq withMapping:nil allowMapping:NO onlyResourceStream:YES fileName:fileName completionHandler:handler intermediate:intermediateCallback];
    [sharedCoordinator->_streamDict setValue:stream forKey:operationID];
    [stream release];*/
    
    
    uploadUrlString = [uploadUrlString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    uploadUrlString = [uploadUrlString stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
    uploadUrlString = [uploadUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    id opID = nil;
    
    if ([fileData length]>0) {
        opID =  [[PWCHTTPClient sharedClient] uploadDataTo:uploadUrlString headers:header fileName:fileName data:fileData success:^(AFUploadRequestOperation *operation, id responseObject) {
            
            {
                NSNumber *finalDocId = nil;
                NSString *responseString = nil;
                //NSError *error = nil;
                
                responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
                
                NSSet *contentSet = [[NSSet alloc] initWithObjects:@"text/plain", nil];
                NSString *contentType = [operation.response MIMEType];
                BOOL checkResponseString  = ![contentSet containsObject:contentType];
                [contentSet release];
                NSDictionary *result = nil;
                NSError *errorObj = nil;
                if(responseString && checkResponseString) {
                    NSArray *parts = [responseString componentsSeparatedByString:@";"];
                    if ([parts count] > 1) {
                        NSString *docId = [parts objectAtIndex:1];
                        NSArray *docPart = [docId componentsSeparatedByString:@"^"];
                        if(docPart.count > 1){
                            long longDocValue = [[docPart objectAtIndex:1] longLongValue];
                            if(longDocValue >= 0)
                                finalDocId = [NSNumber numberWithLong:longDocValue];
                            else{
                                NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"^:"];
                                NSString *status = [parts objectAtIndex:0];
                                NSRange rangeStatus = [status rangeOfCharacterFromSet:cset];
                                NSInteger statusCode = [[status substringFromIndex:rangeStatus.location + 1] integerValue];
                                
                                NSString *description = @"Upload error";
                                NSLog(@"Check response string in operationDone method, some problem with it");
                                if ([parts count] > 2) {
                                    description = [parts objectAtIndex:2];
                                    NSRange rangeDesc = [description rangeOfCharacterFromSet:cset];
                                    description = [description substringFromIndex:rangeDesc.location + 1];
                                }
                                
                                PWCError *serverError = [[PWCError alloc] init];
                                serverError.errorCode = [NSNumber numberWithInt:statusCode];
                                serverError.errorDescription = description;
                                
                                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:serverError,NSLocalizedFailureReasonErrorKey, nil];
                                errorObj = [NSError errorWithDomain:PWCServerErrorDomain code:statusCode userInfo:userInfo];
                                [serverError release];
                            }
                        }
                    }
                    
                    if (finalDocId){
                        result = [NSDictionary dictionaryWithObject:finalDocId forKey:kTargetEntity];
                        handler (YES,result);
                    } else
                        handler (NO,errorObj);
                    
                    [responseString release];
                }
                else{
                    NSLog(@"RESTCoordinator-ShouldNotGetCalled");
                    result = [NSDictionary dictionaryWithObjectsAndKeys:operation.response.allHeaderFields,kResponseHeaderEntity,@"",kTargetEntity, nil];
                    if (responseString) {
                        [responseString release];
                    }
                    handler (YES,result);
                }
            }
            
            if ([[[PWCHTTPClient sharedClient] uploadsQueue] operationCount]==0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:NO]];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_UPDATE_FOR_UI object:operation];
            }

        } failure:^(AFUploadRequestOperation *operation, NSError *error) {
            NSLog(@"Upload Error:%@",error);
            handler(NO,error);
            if ([[[PWCHTTPClient sharedClient] uploadsQueue] operationCount]==0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:NO]];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_UPDATE_FOR_UI object:operation];
            }

        } progressBlock:^(AFUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
            //----Calculate the Progress------//
            operation.dataTransferProgress = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
            
            //----Calculate the time lapsed----//
            /*NSDate *newTimeStamp = [NSDate date];
            NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
            NSDateComponents *components = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:operation.timeStamp toDate:newTimeStamp options:0];
            float timeGap = [components hour] * 3600 + [components minute] * 60 + [components second];
            operation.timeLapsed += timeGap;*/
            //---------------------------------//
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_UPDATE_FOR_UI object:operation];
            
            if (intermediateCallback) {
                intermediateCallback([NSNumber numberWithLongLong:totalBytesWritten]);
            }

        }];
    }
    else {
        
        opID = [[PWCHTTPClient sharedClient] uploadFile:uploadUrlString headers:header localPath:fileName success:^(AFUploadRequestOperation *operation, id responseObject) {

            {
                NSNumber *finalDocId = nil;
                NSString *responseString = nil;
                //NSError *error = nil;
                
                responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
                
                NSSet *contentSet = [[NSSet alloc] initWithObjects:@"text/plain", nil];
                NSString *contentType = [operation.response MIMEType];
                BOOL checkResponseString  = ![contentSet containsObject:contentType];
                [contentSet release];
                NSDictionary *result = nil;
                NSError *errorObj = nil;
                if(responseString && checkResponseString) {
                    NSArray *parts = [responseString componentsSeparatedByString:@";"];
                    if ([parts count] > 1) {
                        NSString *docId = [parts objectAtIndex:1];
                        NSArray *docPart = [docId componentsSeparatedByString:@"^"];
                        if(docPart.count > 1){
                            long longDocValue = [[docPart objectAtIndex:1] longLongValue];
                            if(longDocValue >= 0)
                                finalDocId = [NSNumber numberWithLong:longDocValue];
                            else{
                                NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"^:"];
                                NSString *status = [parts objectAtIndex:0];
                                NSRange rangeStatus = [status rangeOfCharacterFromSet:cset];
                                NSInteger statusCode = [[status substringFromIndex:rangeStatus.location + 1] integerValue];
                                
                                NSString *description = @"Upload error";
                                NSLog(@"Check response string in operationDone method, some problem with it");
                                if ([parts count] > 2) {
                                    description = [parts objectAtIndex:2];
                                    NSRange rangeDesc = [description rangeOfCharacterFromSet:cset];
                                    description = [description substringFromIndex:rangeDesc.location + 1];
                                }
                                
                                PWCError *serverError = [[PWCError alloc] init];
                                serverError.errorCode = [NSNumber numberWithInt:statusCode];
                                serverError.errorDescription = description;
                                
                                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:serverError,NSLocalizedFailureReasonErrorKey, nil];
                                errorObj = [NSError errorWithDomain:PWCServerErrorDomain code:statusCode userInfo:userInfo];
                                [serverError release];
                            }
                        }
                    }
                    
                    if (finalDocId){
                        result = [NSDictionary dictionaryWithObject:finalDocId forKey:kTargetEntity];
                        handler (YES,result);
                    } else
                        handler (NO,errorObj);
                    
                    [responseString release];
                }
                else{
                    NSLog(@"RESTCoordinator-ShouldNotGetCalled");
                    result = [NSDictionary dictionaryWithObjectsAndKeys:operation.response.allHeaderFields,kResponseHeaderEntity,@"",kTargetEntity, nil];
                    if (responseString) {
                        [responseString release];
                    }
                    handler (YES,result);
                }
            }
            
            if ([[[PWCHTTPClient sharedClient] uploadsQueue] operationCount]==0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:NO]];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_UPDATE_FOR_UI object:operation];
            }

        } failure:^(AFUploadRequestOperation *operation, NSError *error) {
            NSLog(@"Upload Error:%@",error);
            handler(NO,error);
            if ([[[PWCHTTPClient sharedClient] uploadsQueue] operationCount]==0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:NO]];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_UPDATE_FOR_UI object:operation];
            }

        } progressBlock:^(AFUploadRequestOperation *operation, NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
            //----Calculate the Progress------//
            operation.dataTransferProgress = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
            
            //----Calculate the time lapsed----//
            /*NSDate *newTimeStamp = [NSDate date];
            NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
            NSDateComponents *components = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:operation.timeStamp toDate:newTimeStamp options:0];
            float timeGap = [components hour] * 3600 + [components minute] * 60 + [components second];
            operation.timeLapsed += timeGap;*/
            //---------------------------------//
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_UPDATE_FOR_UI object:operation];
            
            if (intermediateCallback) {
                intermediateCallback([NSNumber numberWithLongLong:totalBytesWritten]);
            }
        }];
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opID];
    
    if ([[[PWCHTTPClient sharedClient] uploadsQueue] operationCount]>0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:YES]];
    }
    
    return opID;
}

#pragma mark - Project Sync

+ (id)syncProjectWithID:(NSString*)projectID {
    
    NSString *encryptedToken = [PWCNetwork copyAPIToken];
    NSMutableDictionary* dictHeader = [[NSMutableDictionary alloc]initWithObjectsAndKeys:encryptedToken,@"TokenKey",@"1",@"Page",@"1000",@"PerPage", nil];//PerPage
    [encryptedToken release];
    
    NSString *aPath = [NSString stringWithFormat:@"%@?pinProjectId=%@&parentFolderId=0&recursive=1",[PWCProject getURLWithServicePath:[[PWCServices serviceSharedManager] getProjectSyncServicePath]],projectID];//start, orderBy
    
    NSMutableURLRequest *mreq = [[self class] prepareRequestFromUrl:aPath withHeader:dictHeader];
    [mreq setHTTPMethod:@"GET"];
    
    id opID = [[PWCHTTPClient sharedClient] sendRequest:mreq withMapping:nil allowMapping:NO success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"REST RESPONSE FOR SYNC:%@",operation.responseString);
        
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:operation.responseData options:NSJSONReadingAllowFragments error:&error];
        
        if (error==nil && json!=nil) {
            
            [[PWCCoreDataHelper sharedCoreDataHelper] syncFileFolderList:json forProjectId:[NSNumber numberWithInt:[projectID intValue]]];
        }
        else {
            //TODO:implement
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"REST ERROR: %@",error);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opID];
    
    return opID;
}


//change items
/*+ (id)syncProjectWithID:(NSString*)projectID {
    
    NSString *encryptedToken = [PWCNetwork copyAPIToken];
    NSMutableDictionary* dictHeader = [[NSMutableDictionary alloc]initWithObjectsAndKeys:encryptedToken,@"TokenKey",@"PWC",@"AppID", nil];
    [encryptedToken release];
    
    NSString *aPath = [NSString stringWithFormat:@"%@",[PWCProject getURLWithServicePath:[[PWCServices serviceSharedManager] getProjectSyncServicePath]]];
    
    NSArray *body = @[@{@"ProjectID":projectID,@"ItemType":@"Project"}];
    
    NSData *jd = [NSJSONSerialization dataWithJSONObject:body options:NSJSONReadingAllowFragments error:nil];
    
    NSString *ds = [[NSString alloc] initWithData:jd encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *mreq = [[self class] prepareRequestFromUrl:aPath withHeader:dictHeader withBody:ds];
    [mreq setHTTPMethod:@"POST"];
    
    id opID = [[PWCHTTPClient sharedClient] sendRequest:mreq withMapping:nil allowMapping:NO success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"REST RESPONSE FOR SYNC:%@",operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"REST ERROR: %@",error);
    }];
    
    //return [[PWCRestCoordinator restManager] startRequest:mreq withMapping:mapping allowMapping:allowMapping completionHandler:handler ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opID];
    
    return opID;
}*/


#pragma mark - Requests Start

/*- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping completionHandler:(CompletionCallbackBlock)handler {
    return [self startRequest:request withMapping:mapping allowMapping:NO  completionHandler:handler];
}

- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping completionHandler:(CompletionCallbackBlock)handler
// See comment in header.
{
    return [self startRequest:request withMapping:mapping allowMapping:allowMapping onlyResourceStream:NO completionHandler:handler];
}

- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream completionHandler:(CompletionCallbackBlock)handler
{
    return [self startRequest:request withMapping:mapping allowMapping:allowMapping onlyResourceStream:isResourceStream fileName:nil completionHandler:handler intermediate:NULL];
}


- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream fileName:(NSString *)fileName toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler
{
    return [self startRequest:request withMapping:mapping allowMapping:allowMapping onlyResourceStream:isResourceStream fileName:fileName toLocalPath:savePath completionHandler:handler intermediate:NULL];
}


- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream fileName:(NSString *)fileName completionHandler:(CompletionCallbackBlock)handler intermediate:(IntermediateCallbackBlock)intermediateCallBack {
    return [self startRequest:request withMapping:mapping allowMapping:allowMapping onlyResourceStream:isResourceStream fileName:fileName  toLocalPath:nil completionHandler:handler intermediate:intermediateCallBack];
}

//Sayan
- (id)startRequest:(NSURLRequest*)request withMapping:(PWCEntityMapping*)mapping allowMapping:(BOOL)allowMapping onlyResourceStream:(BOOL)isResourceStream  fileName:(NSString *)fileName toLocalPath:(NSString *)savePath completionHandler:(CompletionCallbackBlock)handler intermediate:(IntermediateCallbackBlock)intermediateCallBack {
    // Start the main GET operation, that gets the HTML whose links we want
    // to download.
    if (!self.reachable) {
        [[AlertManager sharedManager] showAlertWithTitle:@"No Internet Connection" Message:@"Please Try Afer Some Time..."];
    }
    PageOperation *op = nil;
    //Default we take the light queue to submit operations
//    self.operatingQueue = self.lightQueue;
//    if (isResourceStream) {
//        self.operatingQueue = self.heavyResourceQueue;
//    }
    
//    NSLog(@"OPERATING QUE: %p",self.operatingQueue);
    
    NSLog(@"URL :%@",[request.URL absoluteString]);
    BOOL success = _runningOperationCount == 0;
    
     //If mapping is present then use its properties to determine the rootkeypath which acts as the key for hte callback dictionary,else
     //set the absolute url as the key
    
    NSString *key = nil;
    if(mapping){
        key = [mapping.objectClass performSelector:@selector(rootKeyPath)];
        if(key){
            //        [PWCRestCoordinator setMapping:mapping forKeyPath:key];
            op = [[PageOperation alloc] initWithRequest:request rootKeyPath:key allowMapping:allowMapping];
        }
        else {
            //        [PWCRestCoordinator addObjectMapping:mapping];
            op = [[PageOperation alloc] initWithRequest:request rootKeyClass:mapping.objectClass allowMapping:allowMapping];
        }
    }
    else{
        key = [request.URL absoluteString];
        op = [[PageOperation alloc] initWithRequest:request downloadDestinationPath:savePath rootKeyPath:key allowMapping:allowMapping];
    }
   
    op.isResourceStream = isResourceStream;
    assert(op != nil);
    NSString *opId = nil;
    //Check if existing / pending request still there otherwise dispatch if needed..
    if([self operationDidStart:op completionHandler:handler]){
        if(isResourceStream){
                if ([op isDownloadingResource]) {
                    [self.downloadOperationHoldingArray addObject:op];
                } else {
                    [self.uploadOperationHoldingArray addObject:op];
                }
                //[self addOperation:op ToQ:self.operatingQueue createNewThread:success];
            [op setIntermediateCallBack:intermediateCallBack];
        } else{
            [self.globalQueue addOperation:op finishedAction:@selector(operationDone:)];
            if (success) {
                [NSThread detachNewThreadSelector:@selector(startMonitoring) toTarget:self withObject:nil];
            }
            else{
                NSLog(@"Already thread dispatched %d operations,",self.runningOperationCount);
                //create operation
            }
        }
        // ... continues in -operationDone:
        op.operationId = [PWCRestCoordinator _generateUUIDString];
        opId = op.operationId;
    }
    else{
        NSLog(@"Already thread dispatched for this operation %@",[request.URL absoluteString]);
        
    }
    
    if (isResourceStream) {
        if (fileName && fileName.length>0) {
            op.fileName = fileName.lastPathComponent;
        }
    }
    [op release];
    
    //Finally check again if operation was dispatched or not ..
    success = _runningOperationCount == 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opId];
    return opId;
}

- (id)startRequest:(NSURLRequest*)request forProcess:(NSString *)processID onlyResourceStream:(BOOL)isResourceStream  fileName:(NSString *)fileName toLocalPath:(NSString *)savePath retryCount:(NSInteger)retry calledAfter:(NSString *)delay completionHandler:(CompletionCallbackBlock)handler {
    // Start the main GET operation, that gets the HTML whose links we want
    // to download.
    PageOperation *op = nil;
    //Default we take the light queue to submit operations
    
    NSLog(@"URL :%@",[request.URL absoluteString]);
    BOOL success = _runningOperationCount == 0;
    
    // If mapping is present then use its properties to determine the rootkeypath which acts as the key for hte callback dictionary,else
     //set the absolute url as the key
     
    NSString *key = [request.URL absoluteString];
        op = [[PageOperation alloc] initWithRequest:request downloadDestinationPath:savePath rootKeyPath:key allowMapping:NO];
    
    op.isResourceStream = isResourceStream;
    [op setRetryCount:retry];
    assert(op != nil);
    NSString *opId = nil;
    //Check if existing / pending request still there otherwise dispatch if needed..
    if([self operationDidStart:op completionHandler:handler]){
        if(isResourceStream){
            if(isResourceStream){
                if ([op isDownloadingResource]) {
                    [self.downloadOperationHoldingArray addObject:op];
                } else {
                    [self.uploadOperationHoldingArray addObject:op];
                }
                //[self addOperation:op ToQ:self.operatingQueue createNewThread:success];
            }
                //[self addOperation:op ToQ:self.operatingQueue createNewThread:success];
                double delayInSeconds = [delay intValue];
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                NSLog(@"Calling %@ in %f secs", NSStringFromSelector(@selector(addOperation:ToQ:createNewThread:)),delayInSeconds);
                    
                    dispatch_after(popTime, dispatch_get_current_queue(),  ^(void){
                        NSLog(@"Calling %@ now",NSStringFromSelector(@selector(addOperation:ToQ:createNewThread:)));
                        [self addOperation:op ToQ:self.downloadQueue createNewThread:success];
                    });
        } else{
            [self.globalQueue addOperation:op finishedAction:@selector(operationDone:)];
            if (success) {
                [NSThread detachNewThreadSelector:@selector(startMonitoring) toTarget:self withObject:nil];
            }
            else{
                NSLog(@"Already thread dispatched %d operations,",self.runningOperationCount);
                //create operation
            }
        }
        // ... continues in -operationDone:
        op.operationId = [PWCRestCoordinator _generateUUIDString];
        opId = op.operationId;
    }
    else{
        NSLog(@"Already thread dispatched for this operation %@",[request.URL absoluteString]);
        
    }
    
    if (isResourceStream) {
        if (fileName && fileName.length>0) {
            op.fileName = fileName.lastPathComponent;
        }
    }
    [op release];
    
    //Finally check again if operation was dispatched or not ..
    success = _runningOperationCount == 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_FOR_NEW_OPID object:opId];
    return opId;
}

- (NSMutableArray*) downloadOperationHoldingArray {
    if (!_downloadOperationHoldingArray) {
        _downloadOperationHoldingArray = [[NSMutableArray alloc] init];
    }
    return _downloadOperationHoldingArray;
}

- (NSMutableArray*) uploadOperationHoldingArray {
    if (!_uploadOperationHoldingArray) {
        _uploadOperationHoldingArray = [[NSMutableArray alloc] init];
    }
    return _uploadOperationHoldingArray;
}

- (NSMutableArray *) allOperations{
    NSMutableArray *allOperations = [NSMutableArray arrayWithArray:[self downloadOperationHoldingArray]];
    [allOperations addObjectsFromArray:[self uploadOperationHoldingArray]];
    return allOperations;
}

- (void)addOperation:(id)op ToQ:(QWatchedOperationQueue*)targetQ createNewThread:(BOOL)newThread {
    //[self operationDidStart];
    //[self.operationHoldingArray addObject:op];
    NSLog(@"OP %@",[op fileName]);
    if (![op isFinished] && ![op isExecuting]) {
        if ([op isDownloadingResource]) {
            self.downloadIterationCounter += 1;
        }
        else{
            self.uploadIterationCounter += 1;
        }
        [targetQ addOperation:op finishedAction:@selector(operationDone:)];
        if (newThread) {
            [NSThread detachNewThreadSelector:@selector(startMonitoring) toTarget:self withObject:nil];
            //        [self startMonitoring];
        }
        else{
            NSLog(@"Already thread dispatched %d operations,",self.runningOperationCount);
            //create operation
        }
        //monitor button now shown only for uploads
        if (self.runningOperationCount == 1 && !monitorEnable && [op isUploadingResource] && [self.uploadOperationHoldingArray containsObject:op] && [op isDownloadingResource] && [self.downloadOperationHoldingArray containsObject:op]) {
            monitorEnable = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:monitorEnable]];
        }
    }
    // ... continues in -operationDone:
}

- (void)resetCounters {
    [self.uploadOperationHoldingArray removeAllObjects];
    [self.downloadOperationHoldingArray removeAllObjects];
    //self.operationHoldingArray = nil;
    //[self.operatingQueue cancelAllOperations];
    //self.operatingQueue = nil;
    _downloadIterationCounter = 0;
    _uploadIterationCounter = 0;
    monitorEnable = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_NETWORK_MONITOR object:[NSNumber numberWithBool:NO]];
}

- (void)startOperationsFromQueue:(QWatchedOperationQueue*)targetQ createNewThread:(BOOL)newThread {
    NSArray *operationArray = Nil;
    NSInteger startIndex = 0;
    if ([targetQ isEqual:self.downloadQueue]) {
        operationArray = self.downloadOperationHoldingArray;
        startIndex = self.downloadIterationCounter;
    }
    else{
        operationArray = self.uploadOperationHoldingArray;
        startIndex = self.uploadIterationCounter;
    }
    //NSInteger length = [operationArray count] - startIndex > MAX_OPERATIONS_CONCURRENTLY ? MAX_OPERATIONS_CONCURRENTLY : [operationArray count] - startIndex;
    if (startIndex < [operationArray count]) {
        //NSIndexSet *operationIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];
        id op = [operationArray objectAtIndex:startIndex];
        [self addOperation:op ToQ:targetQ createNewThread:newThread];
    }// else {
        //[self resetCounters];
    //}
    
}*/

#pragma mark - Cancelling operations
+ (void)doCleanups{
    
    PWCRestCoordinator *theCoordinator = [self restManager];
    @synchronized(theCoordinator){
        CFDictionaryRemoveAllValues(theCoordinator->_operationToCompletionAction);
        [[theCoordinator mapperQueue] cancelAllOperations];
    }
    
    [self cancelAllOperations];
    
    //[[[PWCHTTPClient sharedClient] operationQueue] cancelAllOperations];
    
    //SMB:
    //[theCoordinator setRunningOperationCount:0];
    //[theCoordinator resetCounters];
    //[[theCoordinator allOperations] removeAllObjects];
    
}

+ (void)cancelAllOperations {
    [self cancelOperationsUsingMapping:nil];
    [self cancelAllHeavyOperations];
}

+ (void)cancelAllRESTAndDownloadOperations {
    [[[PWCHTTPClient sharedClient] operationQueue] cancelAllOperations];
    [[[PWCHTTPClient sharedClient] downloadsQueue] cancelAllOperations];
    [[self restManager] removeAllResponseHandler];
}


+ (void)cancelOperationsUsingMapping:(PWCEntityMapping*)mapping {

    /*QWatchedOperationQueue *opQueue = [[self restManager] lightQueue];
    NSArray *allOPerations = [opQueue operations];
    NSString *key = [mapping.objectClass performSelector:@selector(rootKeyPath)];
    NSArray *pageOperations = allOPerations;
    if (mapping) {
        NSPredicate *filter = nil;
        if(key)
            filter = [NSPredicate predicateWithFormat:@"rootKeyPath = %@",key];
        else
            filter = [NSPredicate predicateWithFormat:@"objectClass = %@",mapping.objectClass];
        @try {
            pageOperations = [allOPerations filteredArrayUsingPredicate:filter];
        }
        @catch (NSException *exception) {
            NSLog(@"exception %@",[exception debugDescription]);
            //        pageOperations = nil;
        }
        NSLog(@"cancel %@",filter);
    }

    [pageOperations makeObjectsPerformSelector:@selector(cancel)];*/
    
    NSArray *allOPerations = [[[PWCHTTPClient sharedClient] operationQueue] operations];
    NSString *key = [mapping.objectClass performSelector:@selector(rootKeyPath)];
    NSArray *pageOperations = allOPerations;
    if (mapping) {
        NSPredicate *filter = nil;
        if(key)
            filter = [NSPredicate predicateWithFormat:@"rootKeyPath = %@",key];
        else
            filter = [NSPredicate predicateWithFormat:@"objectClass = %@",mapping.objectClass];
        @try {
            pageOperations = [allOPerations filteredArrayUsingPredicate:filter];
        }
        @catch (NSException *exception) {
            NSLog(@"exception %@",[exception debugDescription]);
            //        pageOperations = nil;
        }
        NSLog(@"cancel %@",filter);
    }
    
    [pageOperations makeObjectsPerformSelector:@selector(cancel)];
    
    
}

+ (void)cancelAllHeavyOperations {

    
    //NSArray *pageOperations = [[self restManager] operationHoldingArray];
    //NSArray *pageOperations = [[[PWCHTTPClient sharedClient] uploadsQueue] operations];
    //[pageOperations makeObjectsPerformSelector:@selector(cancel)];
    [[[PWCHTTPClient sharedClient] uploadsQueue] cancelAllOperations];
    
    //pageOperations = [[[PWCHTTPClient sharedClient] downloadsQueue] operations];
    //[pageOperations makeObjectsPerformSelector:@selector(cancel)];
    [[[PWCHTTPClient sharedClient] downloadsQueue] cancelAllOperations];

}

- (NSInteger)completionDictionaryCount {
    return CFDictionaryGetCount(_operationToCompletionAction);
}

+ (NSInteger)operationCount {
    //NSInteger count = [[PWCRestCoordinator restManager] completionDictionaryCount];//completionDictionaryCount
    //return count;
    
    return [[[PWCHTTPClient sharedClient] operationQueue] operationCount];
}

+ (void)cancelOperationWithID:(id)operationID {

    //NSArray *pageOperations = [[PWCRestCoordinator restManager] operationHoldingArray];
    
    //------Cancel from REST Queue-------//
    NSArray *pageOperations = [[[PWCHTTPClient sharedClient] operationQueue] operations];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"operationId = %@",operationID];
    NSArray *tempArray = [pageOperations filteredArrayUsingPredicate:predicate];
    [tempArray makeObjectsPerformSelector:@selector(cancel)];
    
    //------Cancel from Upload Queue-----//
    if ([tempArray count]==0) {
        pageOperations = [[[PWCHTTPClient sharedClient] uploadsQueue] operations];
        predicate = [NSPredicate predicateWithFormat:@"operationId = %@",operationID];
        tempArray = [pageOperations filteredArrayUsingPredicate:predicate];
        [tempArray makeObjectsPerformSelector:@selector(cancel)];
    }
    
    //------Cancel from Download Queue-----//
    if ([tempArray count]==0) {
        pageOperations = [[[PWCHTTPClient sharedClient] downloadsQueue] operations];
        predicate = [NSPredicate predicateWithFormat:@"operationId = %@",operationID];
        tempArray = [pageOperations filteredArrayUsingPredicate:predicate];
        [tempArray makeObjectsPerformSelector:@selector(cancel)];
    }
    
}

+ (BOOL)canCancelOperationAtIndex:(NSInteger)index {

    //PWCRestCoordinator *thisObj = [PWCRestCoordinator restManager];
    //NSArray *pageOperations = [thisObj operationHoldingArray];
    NSArray *pageOperations = [[[PWCHTTPClient sharedClient] uploadsQueue] operations];
    if (index < [pageOperations count]) {
        return YES;
    } else
        return NO;
}

+ (NSInteger)heavyOperationCount {

    //NSInteger heavyOperationCount = [[[PWCRestCoordinator restManager] operationHoldingArray] count];
    return [[[PWCHTTPClient sharedClient] uploadsQueue] operationCount];
}

+ (void)cancelOperationAtIndex:(NSInteger)index {

    //PWCRestCoordinator *thisObj = [PWCRestCoordinator restManager];
    //NSArray *pageOperations = [thisObj operationHoldingArray];
    NSArray *pageOperations = [[[PWCHTTPClient sharedClient] uploadsQueue] operations];
    if (index < [pageOperations count]) {
        PWCHTTPRequestOperation *op = [pageOperations objectAtIndex:index];
        if ([op respondsToSelector:@selector(cancel)]) {
            NSLog(@"OP %@",[op fileName]);
            [op performSelector:@selector(cancel)];
        }
    }
}

#pragma mark - PWCOperationTarget delegate

- (NSThread*)targetThreadForOperationCallbacks{
    return self.targetThread;
}

#pragma mark - OperationQueue callback


/*- (void)operationDone:(PageOperation *)op
{
    //if (self.inIterationCounter != 0) {
     //self.inIterationCounter -= 1;
     //if (self.inIterationCounter == 0) {
     //self.iterationNumber += 1;
     //[self startOperationsFromQueue:self.operatingQueue createNewThread:NO];
     //[self startOperationsFromQueue:self.heavyResourceQueue createNewThread:NO];
     //}
     //} else if (self.inIterationCounter == [self.operationHoldingArray count] && //[self.operationHoldingArray containsObject:op]) {
     //if (_heavyResourceQueue) {
     //[self resetCounters];
     //}
     //}
    if (self.downloadIterationCounter != 0 && op.isDownloadingResource){
        [self startOperationsFromQueue:self.downloadQueue createNewThread:NO];
    }
    if (self.uploadIterationCounter != 0 && op.isUploadingResource)  {
        [self startOperationsFromQueue:self.uploadQueue createNewThread:NO];
    }
    if (self.downloadIterationCounter == [self.downloadOperationHoldingArray count] && [self.downloadOperationHoldingArray containsObject:op]  && self.runningOperationCount == 1 ) {
        if (_downloadQueue) {
            [self resetCounters];
        }
    }
    if (self.downloadIterationCounter == [self.downloadOperationHoldingArray count] && [self.uploadOperationHoldingArray containsObject:op] && self.runningOperationCount == 1){
        if (_uploadQueue) {
            [self resetCounters];
        }
    }
    
    if ([op isCancelled]) {
        __block PWCRestCoordinator *thisObj = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            CompletionCallbackBlock callback = [thisObj operationDidFinish:op];
            if (op.retryCount > 0) {
                return;
            }
            //handle gracefully when cancelled operation returns callback ...
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"OperationCancelled", nil), NSLocalizedDescriptionKey,nil];
            NSError *cancellationError = [NSError errorWithDomain:PWCLocalErrorDomain code:CancelErrorCode userInfo:userInfo];
            callback(NO,cancellationError);
            Block_release(callback);
        });
        return;
    } else{
        if (op.error != nil) {
            if(op.responseBody && [op.error code] > 0){
                QEntityMapper *mapper = nil;
                NSError *error = nil;
                if ([op isResourceStream] && [op localResourceSavePath].length > 0 && [op isDownloadingResource]) {
                    mapper = [[QEntityMapper alloc] initWithData:[NSData dataWithContentsOfFile:[op localResourceSavePath] options:NSDataReadingMappedIfSafe error:&error] response:op.lastResponse];
                }
                else{
                    mapper = [[QEntityMapper alloc] initWithData:op.responseBody forError:YES];
                }
                [mapper setObjectMapping:[PWCError entityMapping]];
                if(op.rootKeyPath)
                    mapper.rootKeyPath = op.rootKeyPath;
                mapper.operationId = op.operationId;
                mapper.hashValue = op.hash;
                mapper.statusCode = [op.lastResponse statusCode];
                [self.globalQueue addOperation:mapper finishedAction:@selector(mappingDone:)];
                [self performSelectorOnMainThread:@selector(operationDidStart) withObject:nil waitUntilDone:NO];
                [mapper release];
            }
            else{
                //commented so as not to invalidate the entire operation
                //[self stopWithError:op.error];
                __block PWCRestCoordinator *thisObj = self;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    CompletionCallbackBlock callback = [thisObj operationDidFinish:op];
                    callback(NO, op.error); //this calls back with default error.
                    //NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"REQUEST_TIMED_OUT", nil), NSLocalizedDescriptionKey,nil];
                    //NSError *timeOutError = [NSError errorWithDomain:PWCLocalErrorDomain code:RequestTimeOutCode userInfo:userInfo];
                    //callback(NO,timeOutError);
                    Block_release(callback);
                });
                return;
            }
        }
        else {
            if([op shouldMapResponse]){
                //Page operation finished, so need to call it , so as to get the operation count updated
                //            [self operationDidFinish];
//                QEntityMapper *mapper = [[QEntityMapper alloc] initWithData:op.responseBody response:op.lastResponse];
                NSError *error = nil;
                QEntityMapper *mapper = nil;
                if (op.isResourceStream  && [op localResourceSavePath].length > 0 && [op isDownloadingResource]) {
                    mapper = [[QEntityMapper alloc] initWithData:[NSData dataWithContentsOfFile:op.localResourceSavePath options:NSDataReadingMappedIfSafe error:&error] response:op.lastResponse];
                }
                else {
                    mapper = [[QEntityMapper alloc] initWithData:op.responseBody response:op.lastResponse];
                }
                if (op.rootKeyPath) {
                    mapper.objectMapping = [PWCRestCoordinator mappingForKeyPath:op.rootKeyPath];
                    mapper.rootKeyPath = op.rootKeyPath;
                }
                else {
                    mapper.objectMapping = [PWCRestCoordinator objectMappingForClass:op.objectClass];
                }
                mapper.hashValue = op.hash;
                mapper.operationId = op.operationId;
                [self.globalQueue addOperation:mapper finishedAction:@selector(mappingDone:)];
                [self performSelectorOnMainThread:@selector(operationDidStart) withObject:nil waitUntilDone:NO];
                [mapper release];
            }
            else {
                //Since there is no mapping, by default sending the response object so that reciever can extract required data out of it.
                __block PWCRestCoordinator *thisObj = self;
                NSDictionary *headerResponse = op.lastResponse.allHeaderFields;
                
                  //@date 10.09.2013
                  //if header field content conversion waiting eg. ProcessId and TS, will request again for
                  //the file with processid appending with the old url
                  //else will proceed as usual
                 
                NSArray *keys = [headerResponse allKeys];
//#if PWC_PRODUCTION
//                BOOL toRetry = NO;
//                DownloadRequestStatus conversionStatus = ConversionStart;//NoActionYet;
//#else
                BOOL toRetry = NO;
                DownloadRequestStatus conversionStatus = ConverSionStatusNone;//NoActionYet;
//#endif
                NSInteger retryCount = [op retryCount] + 1;
                if ([keys containsObject:CONVERSION_STATUS]) {
                    conversionStatus = [[headerResponse valueForKey:CONVERSION_STATUS] integerValue];
                    //this line below, to test 2 more attempts for fetching file.
                    //conversionStatus = conversionStatus == ConversionDone ? ConversionDone : ConversionFailed;
                    toRetry = (conversionStatus != ConversionDone) && (conversionStatus <= ConversionFailed);
                    // this implemented to retry if very first attempt results in failure. A total of 2 more requests are made to server.
                    if (conversionStatus == ConversionFailed && retryCount <= 3 && [op retryCount] == 1) {  //retry count after failure
                        conversionStatus = ConversionStart;
                        toRetry = YES;
                    }
                }
//#if PWC_PRODUCTION
//                NSString *processID = [headerResponse valueForKey:PROCESS_ID];
//                NSString *delay = [headerResponse valueForKey:TIME_SPAN];
//                if (retryCount <= MAX_RETRY_LIMIT && processID) toRetry = YES;
//#endif
                if (toRetry) {
                    //NSInteger retryCount = [op retryCount] + 1;
                    //if the request not reacing max retry limit and user did not cancel the operation
                    if(retryCount <= MAX_RETRY_LIMIT && [PWCRestCoordinator operationCount] > 0 && conversionStatus != ConversionFailed) {
                        
//#if PWC_PRODUCTION
//                        //nothing to do
//#else
                        NSString *processID = [headerResponse valueForKey:PROCESS_ID];
                        NSString *delay = [headerResponse valueForKey:TIME_SPAN];
//#endif
                        if ([delay intValue] == 0) delay = DEFAULT_TS;
                        NSString *newURL = [op.lastResponse.URL absoluteString];
                        if (retryCount <= 1) {
                            newURL = [newURL stringByAppendingFormat:@"&%@=%@&%@=%@", PROCESS_ID, processID, TIME_SPAN, delay];
                        } else {
                            newURL = [self updatedURLString:newURL WithDelay:delay];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            CompletionCallbackBlock handler = Block_copy([thisObj operationDidFinish:op]);
                            [self downloadResource:newURL forProcess:processID toLocalPath:op.localResourceSavePath retryCount:retryCount calledAfter:delay completionHandler:handler];
                            Block_release(handler);
                        });
                    } else {
                        __block PWCRestCoordinator *thisObj = self;
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            CompletionCallbackBlock callback = [thisObj operationDidFinish:op];
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"COULD_NOT_CONVERT_FILE", nil), NSLocalizedDescriptionKey,nil];
                             NSError *conversionError = [NSError errorWithDomain:PWCServerErrorDomain code:RetryCountExceededCode userInfo:userInfo];
                             callback(NO,conversionError);
                            Block_release(callback);
                        });
                    }
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        CompletionCallbackBlock callback = [thisObj operationDidFinish:op];
                        if (op.isResourceStream) {
                            if(op.error == nil){
                                // "Status^200;DocumentID^1112585; AccountStorageInfo=446466", parsing the following format ... required : DocumentIDx
                                //Status^500;DocumentID^-1;ErrorMsg:There is not enough space on the disk. -- In case of error
                                NSNumber *finalDocId = nil;
                                NSString *responseString = nil;
                                NSError *error = nil;
                                if (op.isResourceStream  && [op localResourceSavePath].length > 0 && [op isDownloadingResource]) {
                                    responseString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:op.localResourceSavePath options:NSDataReadingMappedIfSafe error:&error] encoding:NSUTF8StringEncoding];
                                } else{
                                    responseString = [[NSString alloc] initWithData:op.responseBody encoding:NSUTF8StringEncoding];
                                }
                                NSSet *contentSet = [[NSSet alloc] initWithObjects:@"text/plain", nil];
                                NSString *contentType = [op.lastResponse MIMEType];
                                BOOL checkResponseString  = ![contentSet containsObject:contentType];
                                [contentSet release];
                                NSDictionary *result = nil;
                                NSError *errorObj = nil;
                                if(responseString && checkResponseString) {
                                    NSArray *parts = [responseString componentsSeparatedByString:@";"];
                                    if ([parts count] > 1) {
                                        NSString *docId = [parts objectAtIndex:1];
                                        NSArray *docPart = [docId componentsSeparatedByString:@"^"];
                                        if(docPart.count > 1){
                                            long longDocValue = [[docPart objectAtIndex:1] longLongValue];
                                            if(longDocValue >= 0)
                                                finalDocId = [NSNumber numberWithLong:longDocValue];
                                            else{
                                                NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"^:"];
                                                NSString *status = [parts objectAtIndex:0];
                                                NSRange rangeStatus = [status rangeOfCharacterFromSet:cset];
                                                NSInteger statusCode = [[status substringFromIndex:rangeStatus.location + 1] integerValue];
                                                
                                                NSString *description = @"Upload error";
                                                NSLog(@"Check response string in operationDone method, some problem with it");
                                                if ([parts count] > 2) {
                                                    description = [parts objectAtIndex:2];
                                                    NSRange rangeDesc = [description rangeOfCharacterFromSet:cset];
                                                    description = [description substringFromIndex:rangeDesc.location + 1];
                                                }
                                                
                                                PWCError *serverError = [[PWCError alloc] init];
                                                serverError.errorCode = [NSNumber numberWithInt:statusCode];
                                                serverError.errorDescription = description;
                                                
                                                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:serverError,NSLocalizedFailureReasonErrorKey, nil];
                                                errorObj = [NSError errorWithDomain:PWCServerErrorDomain code:statusCode userInfo:userInfo];
                                                [serverError release];
                                            }
                                        }
                                    }
                                    
                                    if (finalDocId){
                                        result = [NSDictionary dictionaryWithObject:finalDocId forKey:kTargetEntity];
                                        callback (YES,result);
                                    } else
                                        callback (NO,errorObj);
                                    
                                    [responseString release];
                                }
                                else{
                                    result = [NSDictionary dictionaryWithObjectsAndKeys:op.lastResponse.allHeaderFields,kResponseHeaderEntity,op.localResourceSavePath,kTargetEntity, nil];
                                    if (responseString) {
                                        [responseString release];
                                    }
                                    callback (YES,result);
                                }
                            }
                            else{
                                callback(op.error == nil, op.lastResponse);
                            }
                            
                        }
                        else{
                            callback(op.error == nil, op.lastResponse);
                        }
                        Block_release(callback);
                        
                    });
                }
                return;
                
            }
        }
    }
    [self performSelectorOnMainThread:@selector(operationDidFinish) withObject:nil waitUntilDone:NO ];
    
}*/

//for only upload operations
- (int)runningOperationCount {
    return [[[PWCHTTPClient sharedClient] uploadsQueue] operationCount];
}

- (NSArray*)allUploadOperations {
    return [[[PWCHTTPClient sharedClient] uploadsQueue] operations];
}

- (NSArray*)allDownloadOperations {
    return [[[PWCHTTPClient sharedClient] downloadsQueue] operations];
}

- (NSArray*)allRESTOperations {
    return [[[PWCHTTPClient sharedClient] operationQueue] operations];
}

- (NSString*)updatedURLString:(NSString*)urlString WithDelay:(NSString*)delay {
    NSArray *componentsArray = [urlString componentsSeparatedByString:@"="];
    NSString *updatedURLString = [urlString stringByReplacingOccurrencesOfString:[componentsArray lastObject] withString:delay];
    
    return updatedURLString;
}

- (void)mappingDone: (QEntityMapper*)op{
    id returnObject = op.error ? op.error : op.targetObject;
    BOOL isSuccess = op.error == nil;
    NSString *key = [NSString stringWithFormat:@"%u" ,[op hash]];
    CompletionCallbackBlock action;
    //assert( CFDictionaryContainsKey(self->_operationToCompletionAction, (const void *) key) );
    action = (CompletionCallbackBlock) CFDictionaryGetValue(self->_operationToCompletionAction, (const void *) key);
    
    if (action!=NULL) {
        CFDictionaryRemoveValue(self->_operationToCompletionAction, (const void *) key);
        
        if (NO == [op isCancelled])
            action(isSuccess, returnObject);
        Block_release(action);
    }
}

/*- (void)mappingDone: (QEntityMapper*)op{
    //__block id returnObject = op.error ? op.error : op.targetObject;
    //__block BOOL isSuccess = op.error == nil;
    //__block PWCRestCoordinator *thisObj = self;
    
    //  dispatch_sync(dispatch_get_main_queue(), ^{
    //CompletionCallbackBlock callback = [thisObj operationDidFinish:op];
    
    NSLog(@"Mapping Done");
    NSString *key = [NSString stringWithFormat:@"%u" ,[op hash]];
    CompletionCallbackBlock action;
    assert( CFDictionaryContainsKey(self->_operationToCompletionAction, (const void *) key) );
    action = (CompletionCallbackBlock) CFDictionaryGetValue(self->_operationToCompletionAction, (const void *) key);
    CFDictionaryRemoveValue(self->_operationToCompletionAction, (const void *) key);
    
    if (NO == [op isCancelled])
        action(isSuccess, returnObject);
    Block_release(action);
    //  });
}*/

- (void)dealloc{
    
    if (_operationToCompletionAction != NULL) {
        assert(CFDictionaryGetCount(_operationToCompletionAction) == 0);
        CFRelease(_operationToCompletionAction);
    }
    //[_targetThread release];
    [_mappingProvider removeAllObjects];
    [_mappingProvider release];
    [_error release];
    [super dealloc];
}
@end
