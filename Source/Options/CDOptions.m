// CDOptions.m
// cocoadialog
//
// Copyright (c) 2004-2017 Mark A. Stratman <mark@sporkstorms.org>, Mark Carver <mark.carver@me.com>.
// All rights reserved.
// Licensed under GPL-2.

#import "CDOptions.h"

@implementation CDOptions

@synthesize arguments, options, deprecatedOptions, getOptionCallback, getOptionOnceCallback, missingArgumentBreaks, requiredOptions, seenOptions, setOptionCallback, unknownOptions;


#pragma mark - Properties
- (NSArray<NSString *> *) allKeys {
    return options.allKeys;
}

- (NSArray<CDOption *> *) allValues {
    return options.allValues;
}

- (NSDictionary <NSString *, CDOptions *> *) groupByCategories {
    NSMutableDictionary<NSString *, CDOptions *> *categories = [NSMutableDictionary dictionary];
    for (NSString *name in options) {
        CDOption *opt = options[name];
        NSString *category = opt.category != nil ? opt.category : NSLocalizedString(@"USAGE_CATEGORY_CONTROL", nil);
        if (categories[category] == nil) {
            categories[category] = [CDOptions options];
        }
        [categories[category] addOption:opt];
    }
    return categories;
}

- (NSMutableDictionary<NSString *,CDOption *> *)requiredOptions {
    NSMutableDictionary *required = [NSMutableDictionary dictionaryWithDictionary:requiredOptions];
    for (NSString *name in options) {
        CDOption *option = options[name];
        if (option.conditionalRequirements.count) {
            for (NSUInteger i = 0; i < option.conditionalRequirements.count; i++) {
                CDOptionConditionalRequirement block = (CDOptionConditionalRequirement) option.conditionalRequirements[i];
                if (block()) {
                    required[name] = option;
                    break;
                }
            }
        }
        else if (option.required) {
            required[name] = options[name];
        }
    }
    return required;
}

#pragma mark - Private static methods.
+ (BOOL) argIsKey:(NSString *)arg inOptions:(NSDictionary *)options {
    return !!([self isOption:arg] && options[[arg substringFromIndex:2]] != nil);
}

+ (BOOL) isOption:(NSString *)arg {
    return !!(arg && arg.length >= 2 && [[arg substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"--"]);
}

+ (NSString *) optionNameFromArgument:(NSString *)arg {
    return [self isOption:arg] ? [arg substringFromIndex:2] : nil;
}

#pragma mark - Pubic static methods
+ (instancetype) options {
    return [[self alloc] init];
}

#pragma mark - Public instance methods
- (void)addOption:(CDOption *)opt {
    // Add "double dash" note for multiple option values.
    if ([opt.minimumValues unsignedIntegerValue] >= 1 && [opt.maximumValues unsignedIntegerValue] == 0) {
        NSString *doubleDash = NSLocalizedString(@"OPTION_MULTIPLE_DOUBLE_DASH", nil);
        if (![opt.notes containsObject:doubleDash]) {
            [opt.notes addObject:doubleDash];
        }
    }

    if ([opt isKindOfClass:[CDOptionDeprecated class]]) {
        CDOptionDeprecated *deprecated = (CDOptionDeprecated *)opt;
        [deprecatedOptions setObject:deprecated forKey:deprecated.from];
    }
    else {
        [options setObject:opt forKey:opt.name];
    }
}

- (NSUInteger) count {
    return options.count;
}

- (NSString *) getArgument:(unsigned int) index {
    return arguments != nil && index < arguments.count ? arguments[index] : nil;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        arguments = [NSMutableArray array];
        deprecatedOptions = [NSMutableDictionary dictionary];
        options = [NSMutableDictionary dictionary];
        missingArgumentBreaks = [NSMutableArray array];
        requiredOptions = [NSMutableDictionary dictionary];
        seenOptions = [NSMutableArray array];
        unknownOptions = [NSMutableArray array];
    }
    return self;
}


- (instancetype )initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt {
    self = [super init];
    if (self) {
        options = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:cnt];
    }
    return self;
}

- (NSEnumerator *) keyEnumerator {
    return options.keyEnumerator;
}

- (CDOptions *) processArguments {
    NSMutableArray *args = [NSMutableArray arrayWithArray:[NSProcessInfo processInfo].arguments];

    // Remove the command path.
    [args removeObjectAtIndex:0];

    // Parse provided arguments.
    NSString *arg = nil;
    BOOL unknownOption = NO;
    for (NSUInteger i = 0; i < args.count; i++) {
        arg = args[i];

        NSString *optionName = [CDOptions optionNameFromArgument:arg];

        // Capture normal arguments.
        if (optionName == nil) {
            if (!unknownOption) {
                [arguments addObject:arg];
            }
            continue;
        }
        // Skip standalone double dash argument breaks.
        else if ([optionName isBlank]) {
            continue;
        }

        CDOption *option = nil;

        // Handle deprecated options.
        CDOptionDeprecated *deprecated = deprecatedOptions[optionName];
        if (deprecated) {
            if (options[deprecated.to]) {
                deprecated.wasProvided = YES;
                option = options[deprecated.to];
            }
        }
        else {
            option = options[optionName];
        }

        // If provided option isn't actually an available option,
        // add it to the list of unknown options and skip.
        if (!option) {
            [unknownOptions addObject:optionName];
            unknownOption = YES;
            continue;
        }

        unknownOption = NO;

        // Flag that the option was provided.
        option.wasProvided = YES;

        // Retrieve the minimum and maximum values allowed for this option.
        NSUInteger max = [option.maximumValues unsignedIntegerValue];
        NSUInteger min = [option.minimumValues unsignedIntegerValue];

        // Create an array to store values (in case option allows more than one).
        NSMutableArray<NSString *> *values = [NSMutableArray array];

        // No values.
        // @todo Remove once CDOptionFlag is converted to CDOptionBoolean.
        if (min == 0 && max == 0) {
            option.value = @YES;
            continue;
        }

        // Increase index to next argument.
        i++;

        // Determine how many values should be extracted.
        BOOL argumentBreak = NO;
        BOOL possibleOptionsDetected = NO;
        NSUInteger stop = max == 0 ? args.count : i + max;

        // Extract value(s).
        for (; i < stop; i++) {
            // Detect argument breaks.
            argumentBreak = [args[i] isEqualToString:@"--"];

            // Detect possible options.
            if (!argumentBreak && [CDOptions isOption:args[i]]) {
                possibleOptionsDetected = YES;
            }

            // Stop if there are no more arguments or it's a double dash argument break.
            if (i >= args.count || !args[i] || argumentBreak) {
                break;
            }
            [values addObject:args[i]];
        }

        // Keep track of multiple arguments that didn't specify argument breaks.
        if (max == 0 && possibleOptionsDetected && !argumentBreak) {
            [missingArgumentBreaks addObject:optionName];
        }

        // Decrease index since it's exiting the values loop and about
        // to get increased again at the start of the next argument loop.
        i--;

        // Set the provided values on the option.
        [option setValues:values];
    }

    return self;
}

#pragma mark - Enumeration
- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len {
    return [options countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (CDOption *) objectForKey:(NSString *)key {
    CDOption *opt = [options objectForKey:key];
    if (self.getOptionOnceCallback != nil && ![seenOptions containsObject:key]) {
        [seenOptions addObject:key];
        self.getOptionOnceCallback(opt);
    }
    if (self.getOptionCallback != nil) {
        self.getOptionCallback(opt);
    }
    return opt;
}

- (CDOption *) objectForKeyedSubscript:(NSString *)key {
    return [self objectForKey:key];
}

- (void) setObject:(CDOption *)opt forKey:(NSString*)key {
    if (self.setOptionCallback != nil) {
        self.setOptionCallback(opt, key);
    }
    [options setValue:opt forKey:key];
}

- (void) setObject:(CDOption *)opt forKeyedSubscript:(NSString*)key {
    [self setObject:opt forKey:key];
}

@end
