//
//  Inflector.h
//  TrollyDolly
//
//  Created by Tom Ward on 26/05/2009.
//  Copyright 2009 Tom Ward. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ActiveSupportInflector : NSObject {
  NSMutableSet* uncountableWords;
  NSMutableArray* pluralRules;
  NSMutableArray* singularRules;
}

- (void)addInflectionsFromFile:(NSString*)path;
- (void)addInflectionsFromDictionary:(NSDictionary*)dictionary;

- (void)addUncountableWord:(NSString*)string;
- (void)addIrregularRuleForSingular:(NSString*)singular plural:(NSString*)plural;
- (void)addPluralRuleFor:(NSString*)rule replacement:(NSString*)replacement;
- (void)addSingularRuleFor:(NSString*)rule replacement:(NSString*)replacement;

- (NSString*)pluralize:(NSString*)string;
- (NSString*)singularize:(NSString*)string;

+ (ActiveSupportInflector*) instance;

@end
