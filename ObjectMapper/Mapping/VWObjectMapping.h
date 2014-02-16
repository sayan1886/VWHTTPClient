//
//  VWObjectMapping.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VWObjectAttributeMapping.h"

@interface VWObjectMapping : NSObject <NSCopying> {
    Class _objectClass;
    NSMutableArray* _mappings;
    
    NSArray *_dateFormatters;
    NSFormatter *_preferredDateFormatter;
    NSDictionary *_objectPropertiesAndTypes;
}

/**
 The target class this object mapping is defining rules for
 */
@property (nonatomic, assign) Class objectClass;

/**
 The target class properties with their types
 */
@property (nonatomic, retain) NSDictionary *objectPropertiesAndTypes;
/**
 The aggregate collection of attribute and relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *mappings;

/**
 The collection of attribute mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *attributeMappings;

/**
 The collection of relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *relationshipMappings;
/**
 An array of NSDateFormatter objects to use when mapping string values
 into NSDate attributes on the target objectClass. Each date formatter
 will be invoked with the string value being mapped until one of the date
 formatters does not return nil.
 
 Defaults to the application-wide collection of date formatters configured via:
 [VWObjectMapping setDefaultDateFormatters:]
 
 */

@property (nonatomic, retain) NSArray *dateFormatters;

/**
 The NSFormatter object for your application's preferred date
 and time configuration. This date formatter will be used when generating
 string representations of NSDate attributes (i.e. during serialization to
 URL form encoded or JSON format).
 
 Defaults to the application-wide preferred date formatter configured via:
 [VWObjectMapping setPreferredDateFormatter:]
 
 */
@property (nonatomic, retain) NSFormatter *preferredDateFormatter;
/**
 Forces the mapper to treat the mapped keyPath as a collection even if it does not
 return an array or a set of objects. This permits mapping where a dictionary identifies
 a collection of objects.
 
 When enabled, each key/value pair in the resolved dictionary will be mapped as a separate
 entity. This is useful when you have a JSON structure similar to:
 
 { "users":
 {
 "blake": { "id": 1234, "email": "blake@example.in" },
 "rachit": { "id": 5678", "email": "rachit@example.in" }
 }
 }
 
 By enabling forceCollectionMapping, RestKit will map "blake" => attributes and
 "rachit" => attributes as independent objects.  @default NO
 
 */
@property (nonatomic, assign) BOOL forceCollectionMapping;
/**
 When YES, Mapping will check that the object being mapped is key-value coding
 compliant for the mapped key. If it is not, the attribute/relationship mapping will
 be ignored and mapping will continue. When NO, unknown keyPath mappings will generate
 NSUnknownKeyException errors for the unknown keyPath.
 
 Defaults to NO to help the developer catch incorrect mapping configurations during
 development.
 
 **Default**: NO
 */
@property (nonatomic, assign) BOOL ignoreUnknownKeyPaths;
/**
 Returns an object mapping for the specified class that is ready for configuration
 */
+ (id) mappingForClass:(Class)objectClass;

- (void) mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationAttribute;

- (void) mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationAttribute participateInProxy:(BOOL)participate;

- (void) mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(VWObjectMapping *)objectMapping serialize:(BOOL)serialize;

- (void) mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(VWObjectMapping *)objectOrDynamicMapping ;

- (void) mapRelationship:(NSString*)relationshipKeyPath withMapping:(VWObjectMapping *)objectMapping ;

/**
 Check for existence of the attribute mapping in the mapping list
 */
- (BOOL) containsMapping:(VWObjectAttributeMapping*)mapping;

@end

@interface VWObjectMapping (DateAndTimeFormatting)

/**
 Returns the collection of default date formatters that will be used for all object mappings
 that have not been configured specifically.
 
 Out of the box, RestKit initializes the following default date formatters for you in the
 UTC time zone:
 * yyyy-MM-dd'T'HH:mm:ss'Z'
 * MM/dd/yyyy
 
 @return An array of NSFormatter objects used when mapping strings into NSDate attributes
 */
+ (NSArray *)defaultDateFormatters;

/**
 Sets the collection of default date formatters to the specified array. The array should
 contain configured instances of NSDateFormatter in the order in which you want them applied
 during object mapping operations.
 
 @param dateFormatters An array of date formatters to replace the existing defaults
 @see defaultDateFormatters
 */
+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters;

/**
 Adds a date formatter instance to the default collection
 
 @param dateFormatter An NSFormatter object to append to the end of the default formatters collection
 @see defaultDateFormatters
 */
+ (void)addDefaultDateFormatter:(NSFormatter *)dateFormatter;

/**
 Convenience method for quickly constructing a date formatter and adding it to the collection of default
 date formatters. The locale is auto-configured to en_US_POSIX
 
 @param dateFormatString The dateFormat string to assign to the newly constructed NSDateFormatter instance
 @param nilOrTimeZone The NSTimeZone object to configure on the NSDateFormatter instance. Defaults to UTC time.
 @result A new NSDateFormatter will be appended to the defaultDateFormatters with the specified date format and time zone
 @see NSDateFormatter
 */
+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone;

/**
 Returns the preferred date formatter to use when generating NSString representations from NSDate attributes.
 This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations
 that do not have a native time construct.
 
 Defaults to a date formatter configured for the UTC Time Zone with a format string of "yyyy-MM-dd HH:mm:ss Z"
 
 @return The preferred NSFormatter object to use when serializing dates into strings
 */
+ (NSFormatter *)preferredDateFormatter;

/**
 Sets the preferred date formatter to use when generating NSString representations from NSDate attributes.
 This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations
 that do not have a native time construct.
 
 @param dateFormatter The NSFormatter object to designate as the new preferred instance
 */
+ (void)setPreferredDateFormatter:(NSFormatter *)dateFormatter;

@end
