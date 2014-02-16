//
//  PWCEntity.m
//  PlanwellCollaboration
//
//  Created by Abhijit Mukherjee on 05/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PWCEntity.h"
#import "SBJsonWriter.h"
#import "PWCResponseHeader.h"
#import "PWCShareEntity.h"
@implementation PWCEntity
@synthesize markedForDeletion = _markedForDeletion;
@synthesize operationId = _operationId;
@synthesize detailsFetched = _detailsFetched;

+(NSString *)getURLWithServicePath:(NSString*)svcPath{
    PWCServices * services = [PWCServices serviceSharedManager];
    
    //For Production
#if PWC_PRODUCTION
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getSecuredRemoteSite],[services getProductionIP],[services getDomain],svcPath];
#else
#if PWC_LOCAL_DEV
    //local Development
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getRemoteSite],[services getIp],[services getDomain],svcPath];
#else
    //For Amazon
     NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getSecuredRemoteSite],[services getAmazonIP],[services getDomain],svcPath];
    //For Staging
    // NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getRemoteSite],[services getUATIP],[services getDomain],svcPath];
#endif
#endif

    return url;
}

+ (NSString*)getMarkupIPPath {
    PWCServices * services = [PWCServices serviceSharedManager];
      
#if PWC_PRODUCTION
    //For production, need to change markuIP value in serviceURL.pList
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getSecuredRemoteSite],[services getMarkupProductionIP],[services getMarkupDomain],[services getMarkupJsonServlet]];
#else
    //For Amazon
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getSecuredRemoteSite],[services getMarkupIp],[services getMarkupDomain],[services getMarkupJsonServlet]];
#endif
    
    return url;
}

+ (NSString*)getMarkupIPPutPath {
    PWCServices * services = [PWCServices serviceSharedManager];
#if PWC_PRODUCTION
    //For production, need to change markuIP value in serviceURL.pList
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getSecuredRemoteSite],[services getMarkupProductionIP],[services getMarkupDomain],[services getMarkupPutpath]];
#else
    //For Amazon
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/%@",[services getSecuredRemoteSite],[services getMarkupIp],[services getMarkupDomain],[services getMarkupPutpath]];
#endif
   
    return url;
}

//here `fileName` is the GUID of the file i.e. <GUID>.<extension>
+ (NSString*)getMarkupXMLPathForFileName:(NSString*)fileName {
    PWCServices * services = [PWCServices serviceSharedManager];
#if PWC_PRODUCTION
    //For production, need to change markuIP value in serviceURL.pList
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/GetXMLServlet?fileName=%@",[services getSecuredRemoteSite],[services getMarkupProductionIP],[services getMarkupDomain],fileName];
#else
    //For Amazon
    NSString *url = [NSString stringWithFormat:@"%@://%@/%@/GetXMLServlet?fileName=%@",[services getSecuredRemoteSite],[services getMarkupIp],[services getMarkupDomain],fileName];
#endif
    
    return url;
}


+(NSString*)getRequestBody:(id)bodyAsDictionary{
    SBJsonWriter *writer = [[SBJsonWriter alloc]init];
    NSString *str = [writer stringWithObject:bodyAsDictionary];
    [writer release];
    return str;
}

//Child classes provide their own entity mappings and add the attributes mappings in child classes
+ (PWCEntityMapping *)entityMapping{
    PWCEntityMapping *mapping = [PWCRestCoordinator mappingForKeyPath:[self rootKeyPath]];
    mapping = (mapping == nil) ? [PWCRestCoordinator objectMappingForClass:self] : nil;
    return mapping;
}

+ (NSString*)rootKeyPath{
    return nil;
}

+ (void)cancelAllRelatedOperations{
    [PWCRestCoordinator cancelOperationsUsingMapping:[self entityMapping]];
//    [PWCRestCoordinator cancelAllHeavyOperations];
}

+ (void)deleteEntities:(NSArray*)entitiesToDelete atPath:(NSString*)thePath onCompletion:(CompletionCallbackBlock)handler{
    NSMutableArray *deletedInstancesForWebservice = [NSMutableArray arrayWithCapacity:entitiesToDelete.count];
    
    PWCEntity *currentInstance = nil;
    for (PWCEntity *anObj in entitiesToDelete) {
        currentInstance = [anObj newDeleteInstance];
        [deletedInstancesForWebservice addObject:currentInstance];
        [currentInstance release];
    }
    
    [self postEntitites:deletedInstancesForWebservice toPath:thePath mappable:NO onCompletion:handler];
    
}

#pragma mark - utility methods
- (NSString*)description{
    
    NSMutableString *allFieldsWithValues = [NSMutableString string];
    NSArray *keys = [[[[self class] entityMapping] objectPropertiesAndTypes] allKeys];
    for (NSString *key in keys) {
        [allFieldsWithValues appendFormat:@"%@ = %@\r",key,[self valueForKey:key]];
    }
    
    return allFieldsWithValues;
    
}

- (PWCEntity*)newCRUDInstance{
    return [[[self class] alloc] init];
}

//Children override to add their properties ...
- (PWCEntity*)newDeleteInstance{
    return [self newCRUDInstance];
}

- (PWCEntity*)newUpdateInstance{
    return [self newCRUDInstance];
}

- (PWCShareEntity*)createShareEntity{
//Temporary solution as the class change to "ClassName_MAZeroingRefSubclass", so getting rid of this

    NSString *classString  = [NSString stringWithFormat:@"%@Share",NSStringFromClass([self class])];
    PWCShareEntity *sharedInstance = [[NSClassFromString(classString) alloc] init];
    return sharedInstance;
}


- (id) proxyForJson{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss"];
    NSMutableDictionary *dictForJson = [NSMutableDictionary dictionary];
    NSArray *attrMappings = [[[self class] entityMapping] attributeMappings] ;
    for (PWCEntityAttributeMapping *attrMap in attrMappings) {
        id value = [self valueForKey:attrMap.destinationKeyPath] ;
        if ([value isKindOfClass:[NSDate class]]) {
            value = [dateFormatter stringFromDate:value];
        }
        [dictForJson setValue:value forKey:attrMap.sourceKeyPath];
    }
    [dateFormatter release];
    return dictForJson;
}

- (MAZeroingWeakRef*)newWeakReferenceOfSelf{
    MAZeroingWeakRef *weakSelf = [[MAZeroingWeakRef alloc]initWithTarget:self];
    return weakSelf;
}


- (id)copyWithZone:(NSZone*)zone{
    
    id copy = [[[self class] alloc] init];
    id value = nil;
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    
    NSArray *attributeMappings = [[[self class] entityMapping] attributeMappings];
    NSArray *relationMappings = [[[self class] entityMapping] relationshipMappings] ;
    NSMutableArray *allMappings = [NSMutableArray array];
    [allMappings addObjectsFromArray:attributeMappings];
    [allMappings addObjectsFromArray:relationMappings];
    
    for (PWCEntityAttributeMapping *attrMap in allMappings) {
        value = [self valueForKey:attrMap.destinationKeyPath];
        if(value){
            value = [[value copy] autorelease];
            [copy setValue:value forKey:attrMap.destinationKeyPath];
        }
    }
    /*
    for (PWCEntityRelationshipMapping *relMap in relationMappings) {
        value = [self valueForKey:relMap.destinationKeyPath] ;
        if(value){
            value = [[value copy] autorelease];
            [copy setValue:value forKey:relMap.destinationKeyPath];
        }
    }
    */
    [thePool drain];
    return copy;
}
#pragma mark - Rest apis
- (void)uploadImageAtPath:(NSString*)destinationPath fileName:(NSString*)fileNameOrNil withData:(NSData*)srcData onCompletion:(CompletionCallbackBlock)callback{
    
    self.operationId = [[PWCDataManager sharedManager] uploadImageAtPath:destinationPath fileName:fileNameOrNil withData:srcData onCompletion:callback];
    
}

- (void)uploadImageAtPath:(NSString*)destinationPath fileName:(NSString*)fileNameOrNil withData:(NSData*)srcData onCompletion:(CompletionCallbackBlock)callback intermediate:(IntermediateCallbackBlock)intermediateCallBack {
    
   self.operationId = [[PWCDataManager sharedManager] uploadImageAtPath:destinationPath fileName:fileNameOrNil withData:srcData onCompletion:callback intermediate:intermediateCallBack];
    
}

- (void)createEntityAtPath:(NSString*)path onCompletion:(CompletionCallbackBlock)callback{
    PWCEntity *createdObjectForWebservice = [self newCRUDInstance];
    [PWCEntity postEntitites:createdObjectForWebservice toPath:path mappable:NO onCompletion:callback];
    [createdObjectForWebservice release];

}

- (void)updateEntityAtPath:(NSString*)path onCompletion:(CompletionCallbackBlock)callback{

    PWCEntity *updateObjectForWebservice = [self newUpdateInstance];
    [PWCEntity postEntitites:updateObjectForWebservice toPath:path mappable:NO onCompletion:callback];
    [updateObjectForWebservice release];
    
}

- (void)fetchDetailFrom:(NSString*)aPath OnCompletion:(CompletionCallbackBlock)callback{
    
    __block MAZeroingWeakRef *thisObjWeakRef = [self newWeakReferenceOfSelf];
    
    Class thisClass = [self class];
    [thisClass getEntitiesFrom:aPath onCompletion:^(BOOL success, id anObj){
        NSDictionary *outDict = nil;
        PWCEntity *thisObj = [thisObjWeakRef target];
        if (success) {
            thisObj.detailsFetched = YES;
            PWCResponseHeader *resHeader = [anObj valueForKey:kResponseHeaderEntity];
            id targetObj = [anObj valueForKey:kTargetEntity];
            id valueToStore = nil;
            //            NSLog(@"before %@",thisObj);
            NSMutableArray *mappings = [[NSMutableArray alloc] initWithArray:[[thisClass entityMapping] attributeMappings] ];
            [mappings addObjectsFromArray:[[thisClass entityMapping] relationshipMappings]];
            for (PWCEntityAttributeMapping *attrMap in mappings) {
                valueToStore = [targetObj valueForKey:attrMap.destinationKeyPath];
                if (valueToStore)
                    [thisObj setValue:valueToStore forKey:attrMap.destinationKeyPath];
            }
            outDict = [NSDictionary dictionaryWithObjectsAndKeys:resHeader,kResponseHeaderEntity,thisObj,kTargetEntity, nil];
            anObj = outDict;
            [mappings release];
        }
        callback (success,anObj);
        [thisObjWeakRef release];
    }];
    
}


+ (NSMutableDictionary*)newHeaderForOperations{
    NSString *encryptedToken = [PWCNetwork copyAPIToken];
    NSMutableDictionary* dictHeader = [[NSMutableDictionary alloc]initWithObjectsAndKeys:encryptedToken,@"TokenKey", nil];
    [encryptedToken release];
    return dictHeader;    
}

+ (NSMutableDictionary*)newHeaderForOperationsIncludePage:(NSInteger)pageNo{
    NSMutableDictionary *newHeader = [self newHeaderForOperations];
    [newHeader setValue:[[NSNumber numberWithInt:pageNo] stringValue] forKey:@"Page"];
    return newHeader;
}

+ (void)getEntitiesOnCompletion:(CompletionCallbackBlock)callback{
    NSLog(@"Child Classes need to override");
}

+ (void)getEntitiesForPageNumber:(NSInteger)pageNo onCompletion:(CompletionCallbackBlock)callback{
    NSLog(@"Child Classes need to override");
    
}

+ (void)getEntitiesFrom:(NSString*)path onCompletion:(CompletionCallbackBlock)handler{
    
    NSMutableDictionary *dictHeader = [self newHeaderForOperations];
    [self getEntitiesFrom:path withHeader:dictHeader onCompletion:handler];
    [dictHeader release];
    
}

+ (void)getEntitiesFrom:(NSString*)path withHeader:(NSMutableDictionary*)header onCompletion:(CompletionCallbackBlock)handler{
//    [PWCRestCoordinator getRequest:path withModelMapping:[self entityMapping] withHeader:header completionHandler:handler];
    [[PWCDataManager sharedManager] getEntitiesFrom:path withHeader:header withModelMapping:[self entityMapping] onCompletion:handler];
}

+ (void)postEntitites:(id)requestBody toPath:(NSString*)thePath onCompletion:(CompletionCallbackBlock)handler{
    
    [self postEntitites:requestBody toPath:thePath mappable:YES onCompletion:handler];
}

+ (void)postEntitites:(id)requestBody toPath:(NSString*)thePath mappable:(BOOL)isMappable onCompletion:(CompletionCallbackBlock)handler{
    
    NSString *body = [requestBody JSONRepresentation];
    
   [self postJSONEntitites:body toPath:thePath mappable:isMappable onCompletion:handler];
}

+ (void)postJSONEntitites:(NSString*)JSONbody toPath:(NSString*)thePath mappable:(BOOL)isMappable onCompletion:(CompletionCallbackBlock)handler{

//    NSMutableDictionary *headers = [self newHeaderForOperations];
//    [headers setValue:@"application/json" forKey:@"Content-Type"];
//    [PWCRestCoordinator postRequest:thePath withModelMapping:[self entityMapping] withHeader:headers andBody:JSONbody allowMapping:isMappable completionHandler:handler];
//    [headers release];
    [[PWCDataManager sharedManager] postJSONEntitites:JSONbody toPath:thePath mappable:isMappable onCompletion:handler];
}

+ (void)removeCachesFiles {
    NSMutableString *directoryPath = [NSMutableString string];
    [directoryPath appendString:[PWCRestCoordinator tempDirectoryPath]];
    [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:NULL];
}

- (void)dealloc{
    [_operationId release];
    [_markedForDeletion release];
    [super dealloc];
}

@end

@implementation PWCError
@synthesize errorCode = _errorCode;
@synthesize errorDescription = _errorDescription;

+ (PWCEntityMapping*)entityMapping{
    PWCEntityMapping *errorMapping = [super entityMapping];
    if (!errorMapping) {
        
        errorMapping = [PWCEntityMapping mappingForClass:[self class]];
        [errorMapping mapKeyPath:@"ErrorCode" toAttribute:@"errorCode"];
        [errorMapping mapKeyPath:@"ErrorMessage" toAttribute:@"errorDescription"];
      
        [PWCRestCoordinator setMapping:errorMapping forKeyPath:[self rootKeyPath]];
    }
    return errorMapping;
}

+ (NSString*)rootKeyPath{
    return @"Error";
}

- (void)dealloc{
    [_errorDescription release];
    [_errorCode release];
    [super dealloc];
}

@end
