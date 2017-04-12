/*
	AppController.m
	cocoaDialog
	Copyright (C) 2004 Mark A. Stratman <mark@sporkstorms.org>
 
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "AppController.h"
#import "NSString+CDCommon.h"

@implementation AppController

+ (NSString *) appVersion {
    return [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
}

- (NSString *)appVersion {
    return [AppController appVersion];
}

#pragma mark - Initialization
- (void) awakeFromNib {
    // Create the control.
    CDControl *control = [self findControl];

    [control verbose:@"Initiating control: %@", control.controlName.doubleQuote, nil];

    if (control.arguments.deprecatedOptions.count) {
        for (CDOptionDeprecated *deprecated in control.arguments.deprecatedOptions) {
            [control warning:@"The %@ option has been deprecated. Please, use the %@ option instead.", deprecated.from.optionFormat, deprecated.to.optionFormat, nil];
        }
    }

    NSArray *unknown = [control.arguments unknownOptions].sortedAlphabetically;
    if (unknown.count) {
        for (NSString *name in unknown) {
            [control warning:NSLocalizedString(@"UNKNOWN_OPTION", nil), name.optionFormat, nil];
        }
    }

    // Validate control option requirements.
    if (control.arguments.missingOptions.count) {
        NSString *missing = [[control.arguments.missingOptions.allKeys.sortedAlphabetically prependStringsWith:@"--"] componentsJoinedByString:@", "];
        [control fatalError:@"The %@ control requires the following options: %@", control.controlName.doubleQuote, missing, nil];
    }

    // Validate control options values.
    if (![control validateOptions]) {
        [control fatalError:@"Invalid options values provided.", nil];
    }

    // Load the control.
    if (![control loadControlNib:[control controlNib]]) {
        [control fatalError:@"Unable to load control NIB.", nil];
    }

    // Setup the control.
    [control createControl];

    // Initialize the timer, if one exists.
    [control setTimeout];

    // Run the control.
    // The control is now responsible for terminating cocoaDialog,
    // which should be invoked by calling the method [self stopControl]
    // from the control's action method(s).
    [control runControl];
}

#pragma mark - CDControl
+ (NSDictionary *) availableControls {
    return @{
             @"checkbox": [CDCheckboxControl class],
             @"dropdown": [CDPopUpButtonControl class],
             @"fileselect": [CDFileSelectControl class],
             @"filesave": [CDFileSaveControl class],
             @"inputbox": [CDInputboxControl class],
             @"msgbox": [CDMsgboxControl class],
             @"notify": [CDNotifyControl class],
             @"ok-msgbox": [CDOkMsgboxControl class],
             @"progressbar": [CDProgressbarControl class],
             @"radio": [CDRadioControl class],
             @"slider": [CDSlider class],
             @"secure-inputbox": [CDSecureInputboxControl class],
             @"secure-standard-inputbox": [CDSecureStandardInputboxControl class],
             @"standard-dropdown": [CDStandardPopUpButtonControl class],
             @"standard-inputbox": [CDStandardInputboxControl class],
             @"textbox": [CDTextboxControl class],
             @"yesno-msgbox": [CDYesNoMsgboxControl class],
             };
}

- (CDControl *) findControl {
    // Create a base control to use for printing.
    CDControl *control = [[[CDControl alloc] initWithArguments] autorelease];

    // Detect terminal support.
    BOOL terminalSupportsColor = [CDTput supportsColor];

    // Detect --color option override.
    BOOL showColor = terminalSupportsColor;
    if (control.option[@"color"].wasProvided) {
        showColor = control.option[@"color"].boolValue;
    }

    // If there shouldn't be any color, switch off the global variable.
    if (!showColor) {
        NSStringCDColor = NO;
    }

    [control debug:@"Terminal color support: %@", terminalSupportsColor ? NSLocalizedString(@"YES", nil) : NSLocalizedString(@"NO", nil), nil];
    if (control.option[@"color"].wasProvided) {
        [control debug:@"Color option specified, enabled: %@", showColor ? NSLocalizedString(@"YES", nil) : NSLocalizedString(@"NO", nil), nil];
    }

    NSString *name = [control.arguments getArgument:0];
    if (name != nil) {
        name = name.lowercaseString;
    }

    // Show global usage.
    if (name == nil && control.option[@"help"].wasProvided) {
        [control printHelpTo:[NSFileHandle fileHandleWithStandardOutput]];
        exit(0);
    }

    // Show version.
    if ([name isEqualToStringCaseInsensitive:@"version"] || control.option[@"version"].wasProvided) {
        [control writeLn:[AppController appVersion]];
        exit(0);
    }

    // Show about.
    if (name == nil || [name isEqualToStringCaseInsensitive:@"about"]) {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [self setHyperlinkForTextField:aboutAppLink replaceString:@CDSite withURL:@CDSite];
        [self setHyperlinkForTextField:aboutText replaceString:@"command line interface" withURL:@"http://en.wikipedia.org/wiki/Command-line_interface"];
        [self setHyperlinkForTextField:aboutText replaceString:@"documentation" withURL:@"http://mstratman.github.com/cocoadialog/#documentation"];
        [aboutPanel setFloatingPanel: YES];
        [aboutPanel setLevel:NSFloatingWindowLevel];
        [aboutPanel center];
        [aboutPanel makeKeyAndOrderFront:nil];
        [NSApp run];
        exit(0);
    }

    // Control is a notification, these need to be handled much differently
    if ([name isEqualToStringCaseInsensitive:@"notify"] || [name isEqualToStringCaseInsensitive:@"bubble"]) {
        if (control.option[@"help"].wasProvided) {
            control = [AppController createNotifyControlFromArguments:control.arguments];
            [control printHelpTo:[NSFileHandle fileHandleWithStandardOutput]];
            exit(0);
        }

        // Recapture the arguments.
        NSMutableArray *arguments = [[[NSMutableArray alloc] initWithArray:[NSProcessInfo processInfo].arguments] autorelease];
        arguments[1] = @"CDNotifyControl";
        NSString *launcherSource = [[NSBundle mainBundle] pathForResource:@"relaunch" ofType:@""];
        [arguments insertObject:launcherSource atIndex:0];
#if defined __ppc__
        [arguments insertObject:@"-ppc" atIndex:0];
#elif defined __i368__
        [arguments insertObject:@"-i386" atIndex:0];
#elif defined __ppc64__
        [arguments insertObject:@"-ppc64" atIndex:0];
#elif defined __x86_64__
        [arguments insertObject:@"-x86_64" atIndex:0];
#endif
        NSTask *task = [[[NSTask alloc] init] autorelease];
        task.standardError = [NSFileHandle fileHandleWithStandardError];
        task.standardOutput = [NSFileHandle fileHandleWithStandardOutput];
        task.launchPath = @"/usr/bin/arch";
        task.arguments = arguments;
        [control debug:@"Relaunching: %@ %@", task.launchPath, [arguments componentsJoinedByString:@" "], nil];
        [task launch];
        [task waitUntilExit];
        exit(task.terminationStatus);
    }
    else if ([name isEqualToStringCaseInsensitive:@"CDNotifyControl"]) {
        return [AppController createNotifyControlFromArguments:control.arguments];
    }

    Class controlClass = [[AppController availableControls] objectForKey:name];
    if (controlClass == nil) {
        [control fatalError:@"Unknown control: %@\n", name.doubleQuote, nil];
    }

    // Bring application into focus.
    // Because this application isn't going to be double-clicked, or
    // launched with the "open" command-line tool, it won't necessarily
    // come to the front automatically.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    control = [[(CDControl *)[controlClass alloc] initWithArguments] autorelease];
    control.controlName = name;

    // Show control usage.
    if (control.option[@"help"].wasProvided) {
        [control printHelpTo:[NSFileHandle fileHandleWithStandardOutput]];
        exit(0);
    }

    return control;
}

+ (CDNotifyControl *) createNotifyControlFromArguments:(CDArguments *)args {
    Class notifyClass = NSClassFromString(!args.options[@"no-growl"] ? @"CDGrowlControl" : @"CDBubbleControl");
    CDNotifyControl *control = [[(CDNotifyControl *)[notifyClass alloc] initWithArguments] autorelease];
    control.controlName = @"notify";
    return control;
}

#pragma mark - Label Hyperlinks
-(void)setHyperlinkForTextField:(NSTextField*)aTextField replaceString:(NSString *)aString withURL:(NSString *)aURL {
    NSMutableAttributedString *textFieldString = [[aTextField.attributedStringValue mutableCopy] autorelease];
    NSRange range = [textFieldString.string rangeOfString:aString];
    
    // both are needed, otherwise hyperlink won't accept mousedown
    [aTextField setAllowsEditingTextAttributes: YES];
    [aTextField setSelectable: YES];
    
    NSMutableAttributedString* replacement = [[[NSMutableAttributedString alloc] init] autorelease];
    [replacement setAttributedString: [NSAttributedString hyperlinkFromString:aString withURL:[NSURL URLWithString:aURL] withFont:aTextField.font]];
    
    [textFieldString replaceCharactersInRange:range withAttributedString:replacement];
    
    // set the attributed string to the NSTextField
    aTextField.attributedStringValue = textFieldString;
    // Refresh the text field
	[aTextField selectText:self];
    [aTextField currentEditor].selectedRange = NSMakeRange(0, 0);
}

@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL withFont:(NSFont *)aFont {
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, attrString.length);
    
    [attrString beginEditing];
    [attrString addAttribute:NSFontAttributeName value:aFont range:range];
    [attrString addAttribute:NSLinkAttributeName value:aURL.absoluteString range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    [attrString addAttribute:NSCursorAttributeName value:[NSCursor pointingHandCursor]range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:@(NSSingleUnderlineStyle) range:range];
    
    [attrString endEditing];
    
    return [attrString autorelease];
}
@end
