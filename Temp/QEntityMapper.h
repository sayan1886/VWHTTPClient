 //
//  QMapObjectOperation.h
//  PlanwellCollaboration
//
//  Created by Abhijit Mukherjee on 09/06/12.
//  Copyright (c) 2012 CastleRock Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PWCEntityMapping;
@interface QEntityMapper : NSOperation{
    NSData *            _data;
    NSError *           _error;
    NSInteger _statusCode;
    NSMutableArray *    _mutableEntities;
    NSString * _rootKeyPath;
    PWCEntityMapping *_objectMapping;
    id _targetObject;
    
}

- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data forError:(BOOL)isError;
- (id)initWithData:(NSData *)data response:(NSHTTPURLResponse*)aResponse;
- (id)initWithData:(NSData *)data response:(NSHTTPURLResponse*)aResponse forError:(BOOL)isError;
// Things that are configured by the init method and can't be changed.
@property (retain, readwrite) PWCEntityMapping *objectMapping;
@property (copy,   readonly ) NSData *      data;
@property (copy,   readonly ) NSHTTPURLResponse *response;
@property (nonatomic, assign) NSInteger statusCode;
@property (retain, readwrite ) NSString *rootKeyPath;
@property (retain, readonly) id targetObject;
// Things that are only really useful after the operation is finished.
@property (copy,   readonly ) NSError *     error;
@property (copy,   readonly ) NSArray *     entities;
//This is for the purpose of REst Coordinator
@property (nonatomic, assign) NSUInteger hashValue;
@property (nonatomic, retain) NSString *operationId;

- (BOOL)performSynchronousMappingFromJSONString:(id)sourceString;

@end
