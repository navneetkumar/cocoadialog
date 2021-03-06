// CDTerminal.m
// cocoadialog
//
// Copyright (c) 2004-2017 Mark A. Stratman <mark@sporkstorms.org>, Mark Carver <mark.carver@me.com>.
// All rights reserved.
// Licensed under GPL-2.

#import "CDTerminal.h"

@implementation CDTerminal

#pragma mark - Public static methods
+ (instancetype) terminal {
    return [[self alloc] init];
}


#pragma mark - Public instance methods
- (instancetype) init {
    self = [super init];
    if (self) {
        // Private properties.
        fhIn = [NSFileHandle fileHandleWithStandardInput];
        fhErr = [NSFileHandle fileHandleWithStandardError];
        fhOut = [NSFileHandle fileHandleWithStandardOutput];
        which = [NSMutableDictionary dictionary];

        // The "tput" command will throw an error if there is no "TERM"
        // environment variable set. If not, assume terminal is not interactive.
        NSString *term = [[[NSProcessInfo processInfo] environment] objectForKey:@"TERM"];
        if (term == nil || [term isBlank]) {
            _colors = 0;
            _cols = 0;
        }
        else {
            _colors = [[self execute:[self which:@"tput"] withArguments:@[@"colors"]] integerValue];
            _cols = [[self execute:[self which:@"tput"] withArguments:@[@"cols"]] integerValue];
        }
        _supportsColor = _colors >= 8;
    }
    return self;
}

- (NSUInteger) colsWithMinimum:(NSUInteger)minimum {
    if (_cols < minimum) {
        return minimum;
    }
    return _cols;
}

- (NSString *) execute:(NSString *)command withArguments:(NSArray *)arguments {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    [task setLaunchPath:command];
    [task setArguments:arguments];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    NSData *dataRead = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    output = [output stringByReplacingCharactersInSet:[NSCharacterSet newlineCharacterSet] withString:@""];
    return  output;
}

- (void) write:(NSString *)string {
    if (fhOut) {
        [fhOut writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) writeError:(NSString *)string {
    if (fhErr) {
        [fhErr writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) writeLine:(NSString *)string {
    [self write:string];
    [self writeNewLine];
}

- (void) writeNewLine {
    [self write:@"\n"];
}

- (void) writeErrorLine:(NSString *)string{
    [self writeError:string];
    [self writeErrorNewLine];
}

- (void) writeErrorNewLine {
    [self writeError:@"\n"];
}

- (NSString *) which:(NSString *)command {
    if (!which[command]) {
        which[command] = [self execute:@"/usr/bin/which" withArguments:@[command]];
    }
    return which[command];
}


@end
