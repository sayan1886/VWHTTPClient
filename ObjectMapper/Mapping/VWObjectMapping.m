//
//  VWObjectMapping.m
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#import "VWObjectMapping.h"
#import "VWObjectRelationShipMapping.h"
#import "NSObject+PropertySupport.h"

@implementation VWObjectMapping
@synthesize objectClass = _objectClass;
@synthesize dateFormatters = _dateFormatters;
@synthesize preferredDateFormatter = _preferredDateFormatter;
@synthesize objectPropertiesAndTypes = _objectPropertiesAndTypes;
@synthesize mappings = _mappings;
@synthesize forceCollectionMapping = _forceCollectionMapping;
@synthesize ignoreUnknownKeyPaths = _ignoreUnknownKeyPaths;

#pragma mark - Date and Time

+ (id)mappingForClass:(Class)objectClass{
    VWObjectMapping* mapping = [self new];
    mapping.objectClass = objectClass;
    mapping.objectPropertiesAndTypes = [objectClass propertyNamesAndTypes];
    return mapping;
}

- (NSArray *)mappedKeyPaths {
    return [_mappings valueForKey:@"destinationKeyPath"];
}

- (void)addAttributeMapping:(VWObjectAttributeMapping *)mapping {
    NSAssert1([self containsMapping:mapping] == NO, @"Unable to add mapping for keyPath %@, one already exists...", mapping.destinationKeyPath);
    [_mappings addObject:mapping];
}

- (BOOL)containsMapping:(VWObjectAttributeMapping *)mapping{
    return [[self mappedKeyPaths] containsObject:mapping.destinationKeyPath];
}

- (void)addRelationshipMapping:(VWObjectAttributeMapping*)mapping {
    [self addAttributeMapping:mapping];
}

- (NSArray *)attributeMappings {
    NSMutableArray* mappings = [NSMutableArray array];
    for (VWObjectAttributeMapping *mapping in self.mappings) {
        if ([mapping isMemberOfClass:[VWObjectAttributeMapping class]]) {
            [mappings addObject:mapping];
        }
    }
    
    return mappings;
}

- (NSArray *)relationshipMappings {
    NSMutableArray* mappings = [NSMutableArray array];
    for (VWObjectAttributeMapping *mapping in self.mappings) {
        if ([mapping isMemberOfClass:[VWObjectAttributeMapping class]]) {
            [mappings addObject:mapping];
        }
    }
    
    return mappings;
}

- (void)mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationAttribute participateInProxy:(BOOL)participate{
    
    Class type = NSClassFromString([_objectPropertiesAndTypes valueForKey:destinationAttribute]);
    VWObjectAttributeMapping *attribMapping = [VWObjectAttributeMapping mappingFromKeyPath:sourceKeyPath toKeyPath:destinationAttribute withDestinationType:type readyForProxy:participate];
    [_mappings addObject:attribMapping];
}

- (void)mapKeyPath:(NSString*)sourceKeyPath toAttribute:(NSString*)destinationAttribute{
    [self mapKeyPath:sourceKeyPath toAttribute:destinationAttribute participateInProxy:NO];
}

- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(VWObjectMapping *)objectMapping serialize:(BOOL)serialize {
    Class type = NSClassFromString([_objectPropertiesAndTypes valueForKey:keyPath]);
    
    VWObjectRelationShipMapping* mapping = [VWObjectRelationShipMapping mappingFromKeyPath:relationshipKeyPath toKeyPath:keyPath withMapping:objectMapping reversible:serialize];
    mapping.destinationAttributeType = type;
    [self addRelationshipMapping:mapping];
}

- (void) mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString*)keyPath withMapping:(VWObjectMapping *)objectOrDynamicMapping {
    [self mapKeyPath:relationshipKeyPath toRelationship:keyPath withMapping:objectOrDynamicMapping serialize:YES];
}

- (void)mapRelationship:(NSString*)relationshipKeyPath withMapping:(VWObjectMapping *)objectMapping {
    [self mapKeyPath:relationshipKeyPath toRelationship:relationshipKeyPath withMapping:objectMapping];
}

- (NSFormatter *)preferredDateFormatter {
    return _preferredDateFormatter ? _preferredDateFormatter : [VWObjectMapping preferredDateFormatter];
}

- (NSArray *)dateFormatters {
    return _dateFormatters ? _dateFormatters : [VWObjectMapping defaultDateFormatters];
}

#pragma mark - NSObject

- (id)init {
    self = [super init];
    if (self) {
        _mappings = [NSMutableArray new];
        self.forceCollectionMapping = NO;
        self.ignoreUnknownKeyPaths = NO;
        /*
         self.setDefaultValueForMissingAttributes = NO;
         self.setNilForMissingRelationships = NO;
         
         self.performKeyValueValidation = YES;
         
         */
    }
    
    return self;
}

- (NSString*)description{
    return [NSString stringWithFormat:@"Mapping for %@", NSStringFromClass(_objectClass) ];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    VWObjectMapping *copy = [[[self class] allocWithZone:zone] init];
    copy.objectClass = self.objectClass;
    /*
     copy.rootKeyPath = self.rootKeyPath;
     copy.setDefaultValueForMissingAttributes = self.setDefaultValueForMissingAttributes;
     copy.setNilForMissingRelationships = self.setNilForMissingRelationships;
     
     copy.performKeyValueValidation = self.performKeyValueValidation;
     */
    copy.ignoreUnknownKeyPaths = self.ignoreUnknownKeyPaths;
    copy.forceCollectionMapping = self.forceCollectionMapping;
    copy.dateFormatters = self.dateFormatters;
    copy.preferredDateFormatter = self.preferredDateFormatter;
    
    for (VWObjectAttributeMapping *mapping in self.mappings) {
        [copy addAttributeMapping:mapping];
    }
    
    return copy;
}

@end

    /////////////////////////////////////////////////////////////////////////////

static NSMutableArray *defaultDateFormatters = nil;
static NSDateFormatter *preferredDateFormatter = nil;

@implementation VWObjectMapping (DateAndTimeFormatting)

+ (NSArray *)defaultDateFormatters {
    if (!defaultDateFormatters) {
        defaultDateFormatters = [[NSMutableArray alloc] initWithCapacity:2];
        
            // Setup the default formatters
            //        RKISO8601DateFormatter *isoFormatter = [[RKISO8601DateFormatter alloc] init];
            //        [self addDefaultDateFormatter:isoFormatter];
            //        [isoFormatter release];
        
        [self addDefaultDateFormatterForString:@"MM/dd/yyyy" inTimeZone:nil];
        [self addDefaultDateFormatterForString:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" inTimeZone:nil];
    }
    
    return defaultDateFormatters;
}

+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters {
    defaultDateFormatters = nil;
    if (dateFormatters) {
        defaultDateFormatters = [[NSMutableArray alloc] initWithArray:dateFormatters];
    }
}


+ (void)addDefaultDateFormatter:(id)dateFormatter {
    [self defaultDateFormatters];
    [defaultDateFormatters insertObject:dateFormatter atIndex:0];
}

+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = dateFormatString;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    if (nilOrTimeZone) {
        dateFormatter.timeZone = nilOrTimeZone;
    } else {
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    
    [self addDefaultDateFormatter:dateFormatter];
}

+ (NSFormatter *)preferredDateFormatter {
    if (!preferredDateFormatter) {
            // A date formatter that matches the output of [NSDate description]
        preferredDateFormatter = [NSDateFormatter new];
        [preferredDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS Z"];
        preferredDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        preferredDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }
    
    return preferredDateFormatter;
}

+ (void)setPreferredDateFormatter:(NSDateFormatter *)dateFormatter {
    preferredDateFormatter = dateFormatter;
}

@end
