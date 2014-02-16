//
//  ObjectiveResourceDateFormatter.m
//  iphone-harvest
//
//  Created by James Burka on 10/21/08.
//  Copyright 2008 Burkaprojects. All rights reserved.
//

#import "ObjectiveResourceDateFormatter.h"


@implementation ObjectiveResourceDateFormatter 

/*static NSString *dateTimeFormatString = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
static NSString *dateTimeZoneFormatString = @"yyyy-MM-dd'T'HH:mm:ssz";
static NSString *dateFormatString = @"yyyy-MM-dd";*/
static NSString *dateTimeFormatString = @"MM/dd/yyyy'T'HH:mm:ss'Z'";
static NSString *dateTimeZoneFormatString = @"MM/dd/yyyy'T'HH:mm:ssz";
static NSString *dateFormatString = @"MM/dd/yyyy";
static ORSDateFormat _dateFormat;

+ (void)setSerializeFormat:(ORSDateFormat)dateFormat {
	_dateFormat = dateFormat;
}

+ (void)setDateFormatString:(NSString *)format {
	dateFormatString = format;
}

+ (void)setDateTimeFormatString:(NSString *)format {
	dateTimeFormatString = format;
}

+ (void)setDateTimeZoneFormatString:(NSString *)format {
	dateTimeZoneFormatString = format;
}

+ (NSString *)formatDate:(NSDate *)date {
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	if(_dateFormat == Date) {
		[formatter setDateFormat:dateFormatString];
	}
	else {
		[formatter setDateFormat:dateTimeFormatString];		
	}
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	return [formatter stringFromDate:date];
	
}

+ (NSDate *)parseDateTime:(NSString *)dateTimeString {

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSString *format = ([dateTimeString hasSuffix:@"Z"]) ? dateTimeFormatString : dateTimeZoneFormatString;
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:format];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	
	/*---------------------*/
	NSDate	*dt = nil;
	NSError	*err = nil;
	NSString *outputString = nil;
	if ([formatter getObjectValue:&dt forString:dateTimeString range:nil error:&err])
		outputString = [NSString stringWithFormat:@"Date %@", [dt description]];
	else 
		outputString = [NSString stringWithFormat:@"Date error %@",[err description]];
	/*
#ifdef DEBUG
	NSLog(@"dateTimeString = %@",dateTimeString);
	NSLog(@"output = %@",outputString);
#endif	
	*/
	
	return dt;
	/*---------------------*/
	
	//return [formatter dateFromString:dateTimeString];
	
}

+ (NSDate *)parseDate:(NSString *)dateString {
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:dateFormatString];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	//NSDate *result = [formatter dateFromString:dateString];
//	return result;
	
	NSDate	*dt = nil;
	NSError	*err = nil;
	NSString *outputString = nil;
	if ([formatter getObjectValue:&dt forString:dateString range:nil error:&err])
		outputString = [NSString stringWithFormat:@"Date %@", [dt description]];
	else 
		outputString = [NSString stringWithFormat:@"Date error %@",[err description]];
#ifdef DEBUG
//	NSLog(@"dateTimeString = %@",dateString);
//	NSLog(@"output = %@",outputString);
#endif		
	return dt;	
}


@end
