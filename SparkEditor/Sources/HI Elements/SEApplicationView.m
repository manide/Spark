/*
 *  SEApplicationView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEApplicationView.h"

#import <SparkKit/SparkApplication.h>

@implementation SEApplicationView

- (void)dealloc {
  [se_app release];
  [super dealloc];
}

- (SparkApplication *)sparkApplication {
  return se_app;
}
- (void)setSparkApplication:(SparkApplication *)anApp {
  if (se_app != anApp) {
    [se_app release];
    se_app = [anApp retain];
    
    /* Cache icon */
    if (se_app && 0 == [se_app uid]) {
      [super setApplication:[anApp application] title:nil icon:[NSImage imageNamed:@"applelogo"]];
    } else {
      [super setApplication:[anApp application]];
    }
    
    /* Update title and refresh (in setTitle:) */
    NSString *title = nil;
    if (se_app && [se_app uid] == 0) {
      title = [NSLocalizedString(@"Globals HotKeys", @"Globals HotKeys - Application View Title") retain];
    } else {
      title = se_app ? [[NSString alloc] initWithFormat:
        NSLocalizedString(@"%@ HotKeys", @"Application HotKeys - Application View Title (%@ => name)"), [se_app name]] : nil;
    }
    [self setTitle:title];
    [title release];
  }
}

- (NSImage *)defaultIcon {
  if ([se_app icon]) return [se_app icon];
  else return [super defaultIcon];
}

@end
