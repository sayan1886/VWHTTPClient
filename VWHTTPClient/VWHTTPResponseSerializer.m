//
//  VWHTTPResponseSerializer.m
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWHTTPResponseSerializer.h"

#import "VWObjectRelationShipMapping.h"

#define DATE_FORMAT @"MM-dd-yyyy"
#define GENERAL_DATE_FORMAT @"MM/dd/yyyy"
#define SERVER_TIME_FORMAT @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

@interface NSString (Time)
+ (NSDate*)dateFromString:(NSString*)dateString withDateFormat:(NSString*)dateFormat;
@end

@implementation NSString (Time)

+ (NSDate*)dateFromString:(NSString*)dateString withDateFormat:(NSString*)dateFormat {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF contains[c] \"T\""];
    BOOL containtsT = [pred evaluateWithObject:dateString];
    NSRange dotRange = [dateString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
    if (containtsT && dotRange.length == 0) {
        dateString = [dateString stringByAppendingString:@".000"];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

@end

@implementation VWHTTPResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    BOOL valid = [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];
    
//    NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
    
    if (valid) {
        @autoreleasepool {
            
            NSDictionary *mappableValueFromJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
            
                // TODO:    Take care of error,which if present no need to take further parsing and hence fill the Error object appropriately with code and message
            
            id targetObject = nil;
            
            if (mappableValueFromJSON) {
                
                id toMapObject = [mappableValueFromJSON valueForKey:self.rootKeyPath];
                if(!toMapObject || !self.rootKeyPath)
                    toMapObject = mappableValueFromJSON;
                
                BOOL success = YES;
                if ([toMapObject isKindOfClass:[NSArray class]] || [mappableValueFromJSON isKindOfClass:[NSSet class]]) {
                    
                    NSMutableArray *mappedObjects = [NSMutableArray arrayWithCapacity:[toMapObject count]];
                    
                    for (id sourceObjMappings in toMapObject) {
                        id destinationObject = [[self.objectMapping objectClass] new];
                        success = [self performMapping:destinationObject fromObject:sourceObjMappings withMapping:self.objectMapping];
                        if(success)
                            [mappedObjects addObject:destinationObject];
                    }
                    
                    targetObject = mappedObjects;
                }
                else {
                    
                    targetObject = [[self.objectMapping objectClass] new];
                    
                    success = [self performMapping:targetObject fromObject:toMapObject withMapping:self.objectMapping];
                    
                }
                
                if(success){
                    /*
                    NSMutableDictionary *targetObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:targetObject,kTargetEntity, nil];;
                    if (resp) {
                        VWResponseHeader *headerObj = [[VWResponseHeader alloc] init];
                        success = [self performMapping:headerObj fromObject:[resp allHeaderFields] withMapping:[VWResponseHeader entityMapping]];
                        if (success) {
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",kUserLicenseType];
                            NSDictionary *headerDict = [resp allHeaderFields];
                            NSArray *keysArray = [headerDict allKeys];
                            NSArray *tempArray = [keysArray filteredArrayUsingPredicate:predicate];
                            if ([tempArray count] > 0) {
                                
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                for (id key in tempArray) {
                                    NSRange range = [key rangeOfString:@"-"];
                                    NSString *newKey = [key substringFromIndex:range.location + 1];
                                    newKey = [newKey stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
                                    newKey = [newKey stringByAppendingString:ACESS_STRING];
                                    [dict setObject:[headerDict objectForKey:key] forKey:newKey];
                                }
                                [headerObj setValue:dict forKey:@"licenseKeysDictionary"];
                            }
                        }
                        if (success)
                            [targetObjects setValue:headerObj forKey:kResponseHeaderEntity];
                    }
                    
                    targetObject = targetObjects;
                     */
                }
            } else {
                /*
                VWError *errorObject = [VWError new];
                NSString *stringFromResponseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding ];
                if ([stringFromResponseData isEqualToString:@"null"]) {
                    stringFromResponseData = NSLocalizedString(@"ERROR_PROCESSING_REQUEST", @"error processing request");
                }
                errorObject.errorDescription = stringFromResponseData;
                errorObject.errorCode = [NSNumber numberWithInt:[*error code]];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorObject,NSLocalizedFailureReasonErrorKey, nil];
                NSError *tmperror = [NSError errorWithDomain:VWServerErrorDomain code:[*error code] userInfo:userInfo];
                targetObject = tmperror;
                */
            }
            
            return targetObject;
        }
    }
    
    return data;
}


- (BOOL) performMapping:(id)destinationObject fromObject:(id)sourceObject withMapping:(VWObjectMapping *)mapping{
    BOOL mapIsSuccess = NO;
    mapIsSuccess = [self applyAttributeMappingOn:destinationObject fromObject:sourceObject usingMapping:mapping];
    if (mapIsSuccess)
        mapIsSuccess = [self applyRelationshipMappingOn:destinationObject fromObject:sourceObject usingMapping:mapping];
    
    return mapIsSuccess;
}

- (BOOL) applyAttributeMappingOn:(id)destinationObject fromObject:(id)sourceObject usingMapping:(VWObjectMapping *)mapping{
    BOOL mapIsSuccess = YES;
    
    id value = nil;
    Class type = nil;
    
    for (VWObjectAttributeMapping *attrMap in [mapping attributeMappings] ) {
        
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
    
    return mapIsSuccess;
}


- (BOOL) applyRelationshipMappingOn:(id)parentObject fromObject:(id)sourceObject usingMapping:(VWObjectMapping *)mapping{
    BOOL mapIsSuccess = YES;
    id destinationObject = nil;
    for (VWObjectRelationShipMapping *relationship in [mapping relationshipMappings]) {
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
                
                id mappedObject = [[relationship.mapping objectClass] new];
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
            
            VWObjectMapping * relationObjectMapping = relationship.mapping;
            
            NSAssert(relationObjectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
            destinationObject = [[relationObjectMapping objectClass] new];
            if ([self performMapping:destinationObject fromObject:value withMapping:relationObjectMapping]) {
                mapIsSuccess = YES;
                [parentObject setValue:destinationObject forKey:relationship.destinationKeyPath];
            }
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


- (id)transformValue:(id)value atKeyPath:(NSString *)keyPath toType:(Class)destinationType {
    
    Class sourceType = [value class];
    Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
    
    if ([sourceType isSubclassOfClass:[NSString class]]) {
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
                // String -> Date
            return [NSString dateFromString:value withDateFormat:SERVER_TIME_FORMAT];
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
    return nil;
}



#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    VWHTTPResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    
    return serializer;
}


@end
