// CDOption.h
// cocoadialog
//
// Copyright (c) 2004-2017 Mark A. Stratman <mark@sporkstorms.org>, Mark Carver <mark.carver@me.com>.
// All rights reserved.
// Licensed under GPL-2.

// Category extensions.
#import "NSArray+CocoaDialog.h"
#import "NSString+CocoaDialog.h"

// Classes.
#import "CDJson.h"

#pragma mark - Type definitions
typedef id (^CDOptionAutomaticDefaultValue)(void);
typedef BOOL (^CDOptionConditionalRequirement)(void);

#pragma mark -
@interface CDOption : NSObject <CDJsonProtocol> {
    BOOL       _isPercent;
}

#pragma mark - Properties
@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSMutableArray* conditionalRequirements;
@property (nonatomic, copy) id defaultValue;
@property (nonatomic, retain) NSString *helpText;
@property (nonatomic, retain) NSNumber *maximumValues;
@property (nonatomic, retain) NSNumber *minimumValues;
@property (nonatomic, retain) NSMutableArray<NSString *> *notes;
@property (nonatomic, retain) NSMutableArray<NSString *> *warnings;
@property (nonatomic, assign) BOOL required;
@property (nonatomic, retain) id value;
@property (nonatomic, assign) BOOL wasProvided;

#pragma mark - Properties (readonly)
@property (nonatomic, readonly) NSArray* arrayValue;
@property (nonatomic, readonly) BOOL boolValue;
@property (nonatomic, readonly) BOOL hasAutomaticDefaultValue;
@property (nonatomic, readonly) double doubleValue;
@property (nonatomic, readonly) float floatValue;
@property (nonatomic, readonly) int intValue;
@property (nonatomic, readonly) NSInteger integerValue;
@property (nonatomic, readonly) BOOL isPercent;
@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSNumber* numberValue;
@property (nonatomic, readonly) NSNumber* percentValue;
@property (nonatomic, readonly) NSMutableArray* providedValues;
@property (nonatomic, readonly) NSString* stringValue;
@property (nonatomic, readonly) CDColor *typeColor;
@property (nonatomic, readonly) NSString *typeLabel;
@property (nonatomic, readonly) unsigned int unsignedIntValue;
@property (nonatomic, readonly) NSUInteger unsignedIntegerValue;

#pragma mark - Public static methods
+ (instancetype) name:(NSString *)name;
+ (instancetype) name:(NSString *)name value:(id)value;
+ (instancetype) name:(NSString *)name category:(NSString *) category;
+ (instancetype) name:(NSString *)name value:(id)value category:(NSString *) category;
+ (instancetype) name:(NSString *)name value:(id)value category:(NSString *) category helpText:(NSString *)helpText;

#pragma mark - Public instance methods
- (void) addConditionalRequirement:(CDOptionConditionalRequirement)block;
- (void) setValues:(NSArray<NSString *> *)values;

@end

#pragma mark -
@interface CDOptionDeprecated : CDOption {}

#pragma mark - Public static methods
+ (instancetype) from:(NSString *)from to:(NSString *)to;

#pragma mark - Properties
@property (nonatomic, readonly) NSString *from;
@property (nonatomic, readonly) NSString *to;

@end

#pragma mark - Single values
@interface CDOptionSingleString : CDOption @end
@interface CDOptionSingleNumber : CDOption @end
@interface CDOptionSingleStringOrNumber : CDOption @end


#pragma mark - Multiple values
@interface CDOptionMultipleStrings : CDOption @end
@interface CDOptionMultipleNumbers : CDOption @end
@interface CDOptionMultipleStringsOrNumbers : CDOption @end

#pragma mark - Boolean
@interface CDOptionBoolean : CDOptionSingleStringOrNumber @end
@interface CDOptionFlag : CDOption @end

