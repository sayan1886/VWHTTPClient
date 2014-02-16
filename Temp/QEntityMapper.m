//
//  QMapObjectOperation.m
//  PlanwellCollaboration
//
//  Created by Abhijit Mukherjee on 09/06/12.
//  Copyright (c) 2012 CastleRock Research. All rights reserved.
//

#import "QEntityMapper.h"
#import "JSON.h"
#import "PWCEntityMapping.h"
#import "PWCEntity.h"
#import "PWCResponseHeader.h"
#import "QHTTPOperation.h"
#import "PWCConstants.h"


@interface QEntityMapper ()

// Read/write versions of public properties

@property (copy,   readwrite) NSError *         error;

// Internal properties
@property (nonatomic, assign) BOOL errorMapping;
@property (retain, readonly ) NSMutableArray *  mutableEntities;

//Conversion methods to transform to destination types with helpers
- (BOOL) performMapping:(id)destinationObject fromObject:(id)sourceObject withMapping:(PWCEntityMapping*)mapping;
- (BOOL) applyAttributeMappingOn:(id)destinationObject fromObject:(id)sourceObject usingMapping:(PWCEntityMapping*)mapping;
- (BOOL) applyRelationshipMappingOn:(id)destinationObject fromObject:(id)sourceObject usingMapping:(PWCEntityMapping*)mapping;

- (id)transformValue:(id)value atKeyPath:(NSString *)keyPath toType:(Class)destinationType;
- (NSDate*)parseDateFromString:(NSString*)string ;
- (BOOL)isTypeACollection:(Class)type;
- (BOOL)isValueACollection:(id)value ;
@end


@implementation QEntityMapper

@synthesize data  = _data;
@synthesize error = _error;
@synthesize rootKeyPath = _rootKeyPath;
@synthesize objectMapping = _objectMapping;
@synthesize targetObject = _targetObject;
@synthesize statusCode = _statusCode;
@synthesize hashValue = _hashValue;
@synthesize errorMapping = _errorMapping;
@synthesize response = _aresponse;
@synthesize operationId = _operationId;

- (id)initWithData:(NSData *)data
{
    return [self initWithData:data forError:NO];
}

- (id)initWithData:(NSData *)data response:(NSHTTPURLResponse*)aResponse{
    return [self initWithData:data response:aResponse forError:NO];
}

- (id)initWithData:(NSData *)data forError:(BOOL)isError
{
//    assert(data != nil);
    return [self initWithData:data response:nil forError:isError];
}

- (id)initWithData:(NSData *)data response:(NSHTTPURLResponse*)aResponse forError:(BOOL)isError{

    self = [super init];
    if (self != nil) {
        self->_data = [data copy];
        self->_mutableEntities = [[NSMutableArray alloc] init];
        self->_errorMapping = isError;
        self->_aresponse = [aResponse copy];
    }
    return self;

}

- (void)dealloc
{
    [self->_operationId release];
    [self->_targetObject release];
    [self->_rootKeyPath release];
    [self->_mutableEntities release];
    [self->_error release];
    [self->_data release];
    [self->_objectMapping release];
    [self->_aresponse release];
    [super dealloc];
}

- (NSArray *)entities
// This getter returns a snapshot of the current parser state so that, 
// if you call it before the parse is done, you don't get a mutable array 
// that's still being mutated.
{
    return [[self->_mutableEntities copy] autorelease];
}

/*
 We need to confirm that this hash value is the same as the PageOperation has returned,
 as this operation is in continuation to the page operation so the selector against that hash
 value has to be assigned here for dispatching that selector finally from the mapping completion
 of the mapper object.
 */
- (NSUInteger)hash{
    return self.hashValue;
}

@synthesize mutableEntities  = _mutableEntities;

- (void)main
{
    NSAutoreleasePool *collectPool = [[NSAutoreleasePool alloc] init];
    
    NSString *stringFromResponseData = [[[NSString alloc] initWithData:self->_data encoding:NSUTF8StringEncoding ] autorelease];
    
    NSDictionary *mappableValueFromJSON = [stringFromResponseData JSONValue];
// TODO:    Take care of error,which if present no need to take further parsing and hence fill the Error object appropriately with code and message
    
    id targetObject = nil;
    if(mappableValueFromJSON){
        
        id toMapObject = [mappableValueFromJSON valueForKey:self.rootKeyPath];
        if(!toMapObject || !self.rootKeyPath)    
            toMapObject = mappableValueFromJSON;
        // TODO :  check if sourceObject is a ordered collection or dictionary
        BOOL success = YES;
        if ([toMapObject isKindOfClass:[NSArray class]] || [mappableValueFromJSON isKindOfClass:[NSSet class]]) {
            
            NSMutableArray *mappedObjects = [NSMutableArray arrayWithCapacity:[toMapObject count]];
            
            for (id sourceObjMappings in toMapObject) {
                id destinationObject = [[[self.objectMapping objectClass] new] autorelease];
                success = [self performMapping:destinationObject fromObject:sourceObjMappings withMapping:self.objectMapping];
                if(success)
                    [mappedObjects addObject:destinationObject];
            }
            
            targetObject = mappedObjects;
        }
        else{
            if(self.errorMapping){
                PWCEntityMapping *errorMapping = [PWCError entityMapping];
                success = NO;
                id mappableErrorObject = [toMapObject valueForKey:[PWCError rootKeyPath]] ;
                if(!mappableErrorObject)
                    mappableErrorObject = mappableValueFromJSON;
                id errorObject = [[[errorMapping objectClass] new] autorelease];
        //        [self performMapping:errorObject fromObject:mappableErrorObject withMapping:errorMapping];
        //        if ([errorObject errorCode] || [errorObject errorDescription])
                if([self performMapping:errorObject fromObject:mappableErrorObject withMapping:errorMapping])
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorObject,NSLocalizedFailureReasonErrorKey, nil];
                    NSError *error = [NSError errorWithDomain:PWCServerErrorDomain code:[[errorObject errorCode] intValue] userInfo:userInfo];
                    self.error = error;
                }
                else{
                    
                }
            }
            else{
                targetObject = [[[self.objectMapping objectClass] new] autorelease];

                success = [self performMapping:targetObject fromObject:toMapObject withMapping:self.objectMapping];
            }
            
        }
        if(success){
            NSMutableDictionary *targetObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:targetObject,kTargetEntity, nil];;
            if (self.response) {
                PWCResponseHeader *headerObj = [[[PWCResponseHeader alloc] init] autorelease];
                success = [self performMapping:headerObj fromObject:[self.response allHeaderFields] withMapping:[PWCResponseHeader entityMapping]];
                if (success) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",kUserLicenseType];
                    NSDictionary *headerDict = [self.response allHeaderFields];
                    NSArray *keysArray = [headerDict allKeys];
                    NSArray *tempArray = [keysArray filteredArrayUsingPredicate:predicate];
                    if ([tempArray count] > 0) {
                        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                        for (id key in tempArray) {
                            NSRange range = [key rangeOfString:@"-"];
                            NSString *newKey = [key substringFromIndex:range.location + 1];
                            newKey = [newKey stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
                            newKey = [newKey stringByAppendingString:ACESS_STRING];
                            [dict setObject:[headerDict objectForKey:key] forKey:newKey];
                        }
                        [headerObj setValue:dict forKey:@"licenseKeysDictionary"];
                        [dict release];
                    }
                }
                if (success)
                    [targetObjects setValue:headerObj forKey:kResponseHeaderEntity];
            }
            
                
            _targetObject = [targetObjects retain];
        }
    } else {
        PWCError *errorObject = [[PWCError new] autorelease];
        if ([stringFromResponseData isEqualToString:@"null"]) {
            NSLog(@"--------------------------------------------------------");
            NSLog(@"CHECK RESPONSE STRUCTURE TO KNOW WHY ERROR IN PROCESSING");
            NSLog(@"--------------------------------------------------------");
            NSLog(@"RESPONSE BODY: %@",stringFromResponseData);
            stringFromResponseData = NSLocalizedString(@"ERROR_PROCESSING_REQUEST", @"error processing request");
        }
        errorObject.errorDescription = stringFromResponseData;
        errorObject.errorCode = [NSNumber numberWithInt:self->_statusCode];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorObject,NSLocalizedFailureReasonErrorKey, nil];
        NSError *error = [NSError errorWithDomain:PWCServerErrorDomain code:self->_statusCode userInfo:userInfo];
        self.error = error;

    }
    [collectPool drain];
}

#pragma mark - Utility methods 
// TODO: Synchronously using main method ...
- (BOOL)performSynchronousMappingFromJSONString:(id)sourceString{
    
    NSDictionary *sourceObject = [sourceString JSONValue];

    id targetObject = [[[self.objectMapping objectClass] new] autorelease];
    BOOL success = [self performMapping:targetObject fromObject:sourceObject withMapping:self.objectMapping];
    if(success)
        _targetObject = [targetObject retain];
    return success;
    
}


- (BOOL) performMapping:(id)destinationObject fromObject:(id)sourceObject withMapping:(PWCEntityMapping*)mapping{
    BOOL mapIsSuccess = NO;
    mapIsSuccess = [self applyAttributeMappingOn:destinationObject fromObject:sourceObject usingMapping:mapping];
    if (mapIsSuccess)
        mapIsSuccess = [self applyRelationshipMappingOn:destinationObject fromObject:sourceObject usingMapping:mapping];
    
    return mapIsSuccess;
}

- (BOOL) applyAttributeMappingOn:(id)destinationObject fromObject:(id)sourceObject usingMapping:(PWCEntityMapping*)mapping{
    BOOL mapIsSuccess = YES;
    
    id value = nil;
    Class type = nil;
    for (PWCEntityAttributeMapping *attrMap in [mapping attributeMappings] ) {
        if([self isCancelled]){
            mapIsSuccess = NO;
            break;
        }
        else{
            @try {
                value = [sourceObject valueForKey:attrMap.sourceKeyPath];
            }
            @catch (NSException *exception) {
                if ([[exception name] isEqualToString:NSUndefinedKeyException] && self.objectMapping.ignoreUnknownKeyPaths){
                    NSLog(@"Encountered an undefined relationship mapping for keyPath '%@' that generated NSUndefinedKeyException exception. Skipping due to objectMapping.ignoreUnknownKeyPaths = YES",
                          attrMap.sourceKeyPath);
                    continue;
                }
                else
                    mapIsSuccess = NO;
                @throw;
            }

            type = attrMap.destinationAttributeType;
            if (type && NO == [[value class] isSubclassOfClass:type]) {
                value = [self transformValue:value atKeyPath:attrMap.sourceKeyPath toType:type];
            }
            [destinationObject setValue:value forKeyPath:attrMap.destinationKeyPath];
        }
    }

    return mapIsSuccess;
}

- (BOOL) applyRelationshipMappingOn:(id)parentObject fromObject:(id)sourceObject usingMapping:(PWCEntityMapping*)mapping{
    BOOL mapIsSuccess = YES;
    id destinationObject = nil;   
    for (PWCEntityRelationshipMapping *relationship in [mapping relationshipMappings]) {
        if(![self isCancelled]){
            id value = nil;
            @try {
                value = [sourceObject valueForKeyPath:relationship.sourceKeyPath];
            }
            @catch (NSException *exception) {
                if ([[exception name] isEqualToString:NSUndefinedKeyException] && self.objectMapping.ignoreUnknownKeyPaths) {
                    NSLog(@"Encountered an undefined relationship mapping for keyPath '%@' that generated NSUndefinedKeyException exception. Skipping due to objectMapping.ignoreUnknownKeyPaths = YES",
                                 relationship.sourceKeyPath);
                    continue;
                }
                else
                    mapIsSuccess = NO;
                @throw;
            }
            
            if (value == nil || value == [NSNull null] || [value isEqual:[NSNull null]]) {
//                NSLog(@"Did not find mappable relationship value keyPath '%@'", relationship.sourceKeyPath);
                /*
                // Optionally nil out the property
                id nilReference = nil;
                if ([self.objectMapping setNilForMissingRelationships] && [self shouldSetValue:&nilReference atKeyPath:relationship.destinationKeyPath]) {
                    RKLogTrace(@"Setting nil for missing relationship value at keyPath '%@'", relationship.sourceKeyPath);
                    [destinationObject setValue:nil forKeyPath:relationship.destinationKeyPath];
                }
                */
                continue;
            }
            
            // Handle case where incoming content is collection represented by a dictionary
            if (relationship.mapping.forceCollectionMapping) {
                // If we have forced mapping of a dictionary, map each subdictionary
                if ([value isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"Collection mapping forced for NSDictionary, mapping each key/value independently...");
                    NSArray* objectsToMap = [NSMutableArray arrayWithCapacity:[value count]];
                    for (id key in value) {
                        NSDictionary* dictionaryToMap = [NSDictionary dictionaryWithObject:[value valueForKey:key] forKey:key];
                        [(NSMutableArray*)objectsToMap addObject:dictionaryToMap];
                    }
                    value = objectsToMap;
                } else {
                    NSLog(@"Collection mapping forced but mappable objects is of type '%@' rather than NSDictionary", NSStringFromClass([value class]));
                }
            }
            
            // Handle case where incoming content is a single object, but we want a collection
            Class relationshipType = relationship.destinationAttributeType;
            BOOL mappingToCollection = [self isTypeACollection:relationshipType];
            if (mappingToCollection && ![self isValueACollection:value]) {
                Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
                NSLog(@"Asked to map a single object into a collection relationship. Transforming to an instance of: %@", NSStringFromClass(relationshipType));
                if ([relationshipType isSubclassOfClass:[NSArray class]]) {
                    value = [relationshipType arrayWithObject:value];
                } else if ([relationshipType isSubclassOfClass:[NSSet class]]) {
                    value = [relationshipType setWithObject:value];
                } else if (orderedSetClass && [relationshipType isSubclassOfClass:orderedSetClass]) {
                    value = [relationshipType orderedSetWithObject:value];
                } else {
                    NSLog(@"Failed to transform single object");
                }
            }
            
            if ([self isValueACollection:value]) {
                // One to many relationship
                NSLog(@"Mapping one to many relationship value at keyPath '%@' to '%@'", relationship.sourceKeyPath, relationship.destinationKeyPath);
                mapIsSuccess = YES;
                
                destinationObject = [NSMutableArray arrayWithCapacity:[value count]];
                id collectionSanityCheckObject = nil;
                if ([value respondsToSelector:@selector(anyObject)]) collectionSanityCheckObject = [value anyObject];
                if ([value respondsToSelector:@selector(lastObject)]) collectionSanityCheckObject = [value lastObject];
                if ([self isValueACollection:collectionSanityCheckObject]) {
                    NSLog(@"WARNING: Detected a relationship mapping for a collection containing another collection. This is probably not what you want. Consider using a KVC collection operator (such as @unionOfArrays) to flatten your mappable collection.");
                    NSLog(@"Key path '%@' yielded collection containing another collection rather than a collection of objects: %@", relationship.sourceKeyPath, value);
                }
                for (id nestedObject in value) {
                    
                    id mappedObject = [[[relationship.mapping objectClass] new] autorelease];
                    [self performMapping:mappedObject fromObject:nestedObject withMapping:relationship.mapping];
                    [destinationObject addObject:mappedObject];
                    
                }
                
                // Transform from NSSet <-> NSArray if necessary
                if (relationshipType && NO == [[destinationObject class] isSubclassOfClass:relationshipType]) {
                    destinationObject = [self transformValue:destinationObject atKeyPath:relationship.sourceKeyPath toType:relationshipType];
                }
                
                [parentObject setValue:destinationObject forKeyPath:relationship.destinationKeyPath];

            }
            else{
                
                    // One to one relationship
//                    NSLog(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationship.sourceKeyPath, relationship.destinationKeyPath);
                    
                    PWCEntityMapping * relationObjectMapping = relationship.mapping;
                /*
                    RKObjectMapping* objectMapping = nil;
                    if ([mapping isKindOfClass:[RKDynamicObjectMapping class]]) {
                        objectMapping = [(RKDynamicObjectMapping*)mapping objectMappingForDictionary:value];
                    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                        objectMapping = (RKObjectMapping*)mapping;
                    }
                 */
                    NSAssert(relationObjectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
                    destinationObject = [[[relationObjectMapping objectClass] new] autorelease];
                    if ([self performMapping:destinationObject fromObject:value withMapping:relationObjectMapping]) {
                        mapIsSuccess = YES;
                        [parentObject setValue:destinationObject forKey:relationship.destinationKeyPath];
                    }
                /*
                    if ([self mapNestedObject:value toObject:destinationObject withRealtionshipMapping:relationshipMapping]) {
                        appliedMappings = YES;
                    }
                    
                    // If the relationship has changed, set it
                    if ([self shouldSetValue:&destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
                        appliedMappings = YES;
                        RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
                    } else {
                        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
                            [self.delegate objectMappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
                        }
                    }
                */
            }
        }
        else{
            mapIsSuccess = NO;
            break;
        }
    }
    return mapIsSuccess;

}

- (BOOL)isTypeACollection:(Class)type {
    Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
    return (type && ([type isSubclassOfClass:[NSSet class]] ||
                     [type isSubclassOfClass:[NSArray class]] ||
                     (orderedSetClass && [type isSubclassOfClass:orderedSetClass])));
}

- (BOOL)isValueACollection:(id)value {
    return [self isTypeACollection:[value class]];
}

- (NSDate*)parseDateFromString:(NSString*)string {
//    RKLogTrace(@"Transforming string value '%@' to NSDate...", string);
    
    NSDate* date = nil;
    NSRange dotRange = [string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
//For some date strings, milliseconds are missing so appending it
    
    NSString *alteredString = string;
    if(dotRange.location == NSNotFound)
        alteredString = [string stringByAppendingString:@".000"];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSNumber *numeric = [numberFormatter numberFromString:alteredString];
    
    [numberFormatter release];
    
    if (numeric) {
        date = [NSDate dateWithTimeIntervalSince1970:[numeric doubleValue]];
    } else if(![alteredString isEqualToString:@""]) {
        NSArray *formatters = [NSArray arrayWithArray:self.objectMapping.dateFormatters];
        for (NSFormatter *dateFormatter in formatters) {
            BOOL success;
            @synchronized(dateFormatter) {
                if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
//                    RKLogTrace(@"Attempting to parse string '%@' with format string '%@' and time zone '%@'", string, [(NSDateFormatter *)dateFormatter dateFormat], [(NSDateFormatter *)dateFormatter timeZone]);
                }
                NSString *errorDescription = nil;
                success = [dateFormatter getObjectValue:&date forString:alteredString errorDescription:&errorDescription];
            }
            
            if (success && date) {
                if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
//                    RKLogTrace(@"Successfully parsed string '%@' with format string '%@' and time zone '%@' and turned into date '%@'",                               string, [(NSDateFormatter *)dateFormatter dateFormat], [(NSDateFormatter *)dateFormatter timeZone], date);
                }
                
                break;
            }
        }
    }
    
    return date;
}

- (id)transformValue:(id)value atKeyPath:(NSString *)keyPath toType:(Class)destinationType {
//    RKLogTrace(@"Found transformable value at keyPath '%@'. Transforming from type '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));
    Class sourceType = [value class];
    Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
    
    if ([sourceType isSubclassOfClass:[NSString class]]) {
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            // String -> Date
            return [NSString dateFromString:value withDateFormat:SERVER_TIME_FORMAT];//[self parseDateFromString:(NSString*)value];//
        } else if ([destinationType isSubclassOfClass:[NSURL class]]) {
            // String -> URL
            return [NSURL URLWithString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
            // String -> Decimal Number
            return [NSDecimalNumber decimalNumberWithString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSNumber class]]) {
            // String -> Number
            NSString* lowercasedString = [(NSString*)value lowercaseString];
            NSSet* trueStrings = [NSSet setWithObjects:@"true", @"t", @"yes", nil];
            NSSet* booleanStrings = [trueStrings setByAddingObjectsFromSet:[NSSet setWithObjects:@"false", @"f", @"no", nil]];
            if ([booleanStrings containsObject:lowercasedString]) {
                // Handle booleans encoded as Strings
                return [NSNumber numberWithBool:[trueStrings containsObject:lowercasedString]];
            } else {
                return [NSNumber numberWithDouble:[(NSString*)value doubleValue]];
            }
        }
    } else if (value == [NSNull null] || [value isEqual:[NSNull null]]) {
        // Transform NSNull -> nil for simplicity
        return nil;
    } else if ([sourceType isSubclassOfClass:[NSSet class]]) {
        // Set -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [(NSSet*)value allObjects];
        }
    } else if (orderedSetClass && [sourceType isSubclassOfClass:orderedSetClass]) {
        // OrderedSet -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [value array];
        }
    } else if ([sourceType isSubclassOfClass:[NSArray class]]) {
        // Array -> Set
        if ([destinationType isSubclassOfClass:[NSSet class]]) {
            return [NSSet setWithArray:value];
        }
        // Array -> OrderedSet
        if (orderedSetClass && [destinationType isSubclassOfClass:orderedSetClass]) {
            return [orderedSetClass orderedSetWithArray:value];
        }
    } else if ([sourceType isSubclassOfClass:[NSNumber class]] && [destinationType isSubclassOfClass:[NSDate class]]) {
        // Number -> Date
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            return [NSDate dateWithTimeIntervalSince1970:[(NSNumber*)value intValue]];
        } else if ([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] && [destinationType isSubclassOfClass:[NSString class]]) {
            return ([value boolValue] ? @"true" : @"false");
        }
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber*)value doubleValue]];
    } else if ([sourceType isSubclassOfClass:[NSNumber class]] && [destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
        // Number -> Decimal Number
        return [NSDecimalNumber decimalNumberWithDecimal:[value decimalValue]];
    } else if ( ([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] ||
                 [sourceType isSubclassOfClass:NSClassFromString(@"NSCFBoolean")] ) &&
               [destinationType isSubclassOfClass:[NSString class]]) {
        return ([value boolValue] ? @"true" : @"false");
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            return [NSDate dateWithTimeIntervalSince1970:[(NSNumber*)value intValue]];
        } else if (([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] || [sourceType isSubclassOfClass:NSClassFromString(@"NSCFBoolean")]) && [destinationType isSubclassOfClass:[NSString class]]) {
            return ([value boolValue] ? @"true" : @"false");
        }
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSDate class]]) {
        // NSDate -> NSString
        // Transform using the preferred date formatter
        NSString* dateString = nil;
        @synchronized(self.objectMapping.preferredDateFormatter) {
            dateString = [self.objectMapping.preferredDateFormatter stringForObjectValue:value];
        }
        return dateString;
    }
    
//    RKLogWarning(@"Failed transformation of value at keyPath '%@'. No strategy for transforming from '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));
    
    return nil;
}

@end
