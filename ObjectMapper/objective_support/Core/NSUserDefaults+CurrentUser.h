//
//  NSUserDefaults+CurrentUser.h
//  PlanwellCollaboration
//
//  Created by Srabati Sarkar on 28/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (CurrentUser)

+ (void)loadForUser:(NSString *)userName;
+ (void)synchronizeForCurrentUser;

@end
