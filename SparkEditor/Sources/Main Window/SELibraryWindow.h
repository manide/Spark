/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SEApplicationView, SETableView;
@class SparkLibrary, SparkApplication;
@class SELibrarySource, SETriggersController;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSButton *ibDaemon;
  IBOutlet NSTextField *ibStatus;
  IBOutlet NSSegmentedControl *ibMenu;
  IBOutlet SEApplicationView *appField;  
  
  /* Application */
  IBOutlet NSDrawer *appDrawer;
  
  /* Library */
  IBOutlet SETableView *libraryTable;
  IBOutlet SELibrarySource *listSource;
  
  /* Triggers */
  IBOutlet SETriggersController *triggers;  
}

- (SparkLibrary *)library;
- (NSUndoManager *)undoManager;
- (SparkApplication *)application;

@end

SK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;