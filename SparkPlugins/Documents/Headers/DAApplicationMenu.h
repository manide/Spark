/*
 *  DAApplicationMenu.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface DAApplicationMenu : NSPopUpButton

- (NSMenuItem *)itemForURL:(NSURL *)path;
- (void)loadAppForDocument:(NSURL *)path;

@end
