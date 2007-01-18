/*
 *  SEEntriesManager.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkApplication, SparkPlugIn;
@class SESparkEntrySet, SEEntryEditor;
@class SparkEntry;
@interface SEEntriesManager : NSObject {
  @private
  SparkLibrary *se_library;
  
  SEEntryEditor *se_editor;
  SparkApplication *se_app;
  SESparkEntrySet *se_globals;
  SESparkEntrySet *se_snapshot;
  SESparkEntrySet *se_overwrites;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

/* Flush cache and reload */
- (void)reload;

/* reload without flushing cache */
- (void)refresh;

- (SparkLibrary *)library;

/* All globals entries */
- (SESparkEntrySet *)globals;
/* Current entryset */
- (SESparkEntrySet *)snapshot;
/* Current application entries */
- (SESparkEntrySet *)overwrites;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

- (unsigned)removeEntries:(NSArray *)entries;

- (SparkEntry *)createWeakEntryForEntry:(SparkEntry *)anEntry;

- (void)createEntry:(SparkPlugIn *)aPlugin modalForWindow:(NSWindow *)aWindow;
- (void)editEntry:(SparkEntry *)anEntry modalForWindow:(NSWindow *)aWindow;

@end

SK_PRIVATE
NSString * const SEEntriesManagerDidReloadNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidCreateEntryNotification;

SK_PRIVATE
NSString * const SEEntriesManagerDidUpdateEntryNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidCreateWeakEntryNotification;