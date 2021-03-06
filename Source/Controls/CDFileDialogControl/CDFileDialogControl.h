// CDFileDialogControl.h
// cocoadialog
//
// Copyright (c) 2004-2017 Mark A. Stratman <mark@sporkstorms.org>, Mark Carver <mark.carver@me.com>.
// All rights reserved.
// Licensed under GPL-2.

#import "CDControl.h"


@interface CDFileDialogControl : CDControl <NSOpenSavePanelDelegate> {
    NSSavePanel *savePanel;
    NSMutableArray * extensions;
}

- (BOOL) isExtensionAllowed:(NSString *)filename;

// Set options common to any file save panel
- (void) setMisc;

@end
