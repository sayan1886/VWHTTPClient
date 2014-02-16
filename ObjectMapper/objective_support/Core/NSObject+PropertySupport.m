//
//  NSObject+Properties.m
//  
//
//  Created by Ryan Daigle on 7/28/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

#import "objc/runtime.h"
#import "NSObject+PropertySupport.h"

@interface NSObject()

+ (NSString *) getPropertyType:(NSString *)attributeString;

@end


@implementation NSObject (PropertySupport)
+ (NSArray *)propertyNames {
	return [[self propertyNamesAndTypes] allKeys];
}

+ (NSDictionary *)propertyNamesAndTypes {
	NSMutableDictionary *propertyNames = [NSMutableDictionary dictionary];
	
	//include superclass properties
	Class currentClass = [self class];
	while (currentClass != nil) {
		// Get the raw list of properties
		unsigned int outCount;
		objc_property_t *propList = class_copyPropertyList(currentClass, &outCount);
		
		// Collect the property names
		int i;
		NSString *propName;
		for (i = 0; i < outCount; i++)
		{
			objc_property_t * prop = propList + i;
			NSString *type = [NSString stringWithCString:property_getAttributes(*prop) encoding:NSUTF8StringEncoding];
			propName = [NSString stringWithCString:property_getName(*prop) encoding:NSUTF8StringEncoding];

			NSString *propertyType = [self getPropertyType:type];
			if (nil != propertyType &&
				![propName isEqualToString:@"_mapkit_hasPanoramaID"] &&
				![propName isEqualToString:@"_textSelectingContainer"] &&
				![propName isEqualToString:@"URLValue"] &&
				![propName isEqualToString:@"accessibilityLanguage"] &&
				![propName isEqualToString:@"accessibilityFrame"] &&
				![propName isEqualToString:@"accessibilityTraits"] &&
				![propName isEqualToString:@"accessibilityHint"] &&
				![propName isEqualToString:@"accessibilityValue"] &&
				![propName isEqualToString:@"accessibilityLabel"] &&
				![propName isEqualToString:@"isAccessibilityElement"]) {
				[propertyNames setObject:propertyType forKey:propName];
			}
		}
		
		free(propList);
		currentClass = [currentClass superclass];
	}
	
	return propertyNames;
}


- (NSDictionary *)properties {
	return [self dictionaryWithValuesForKeys:[[self class] propertyNames]];
}

- (void)setProperties:(NSDictionary *)overrideProperties {
	for (NSString *property in [overrideProperties allKeys]) 
	{
		id value = [overrideProperties objectForKey:property];
		if([value isKindOfClass:[NSNull class]]){
			//value = [NSNull null];
            continue;
        }   
        if ([value isKindOfClass:[NSDecimalNumber class]]){
            NSString *str = [value stringValue];
//            [self setValue:str forKey:property];
            @try {
                [self setValue:str forKey:property];
            }
            @catch (NSException *exception) {
                NSLog(@"----------changes in service side-------------");
            }
            continue;
        }
        @try {
            [self setValue:value forKey:property];
        }
        @catch (NSException *exception) {
            NSLog(@"----------changes in service side-------------");
        }
      
//    	[self setValue:value forKey:property];
	}
}

+ (NSString *) getPropertyType:(NSString *)attributeString {
	NSString *type = nil;
	NSScanner *typeScanner = [NSScanner scannerWithString:attributeString];
	[typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"] intoString:NULL];
	
	if(![typeScanner isAtEnd]) {
		// We didn't hit the end, so we have an object type
		[typeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"@"] intoString:NULL];
		// this gets the actual object type
		[typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&type];
	}
	
	return type;
}

- (NSString *)className {
	return NSStringFromClass([self class]);
}

@end
