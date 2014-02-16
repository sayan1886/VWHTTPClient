//
//  NSUserDefaults+CurrentUser.m
//  PlanwellCollaboration
//
//  Created by Srabati Sarkar on 28/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSUserDefaults+CurrentUser.h"

static NSString *currentUser;

@implementation NSUserDefaults (CurrentUser)

+ (void)loadForUser:(NSString *)userName {
	currentUser = [userName copy];
    
	NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"userSettings"];
	if (!userSettings) return;
    
	NSDictionary *settings = [userSettings valueForKey:currentUser];
	if (!settings) return;
    
	for (id key in settings)
		[[NSUserDefaults standardUserDefaults] setObject:[settings objectForKey:key] forKey:key];
}

+ (void)synchronizeForCurrentUser {
	[[NSUserDefaults standardUserDefaults] synchronize];
    
	if (!currentUser) {
#ifdef DEBUG
		NSLog(@"Failed to sync for the current user.");
#endif
		return;
	}
    
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
#ifdef DEBUG	
    //	NSLog(@"Settings: %@", dict);
#endif
	[dict removeObjectForKey:@"userSettings"];
	NSMutableDictionary *userSettings = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"userSettings"]];
	[userSettings setObject:dict forKey:currentUser];
    
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
