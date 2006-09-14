/* 
 *  SparkActionPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

@implementation SparkActionPlugIn

- (void)dealloc {
  if (sp_sapFlags.ownership)
    [sp_view release];
  [sp_action release];
  [super dealloc];
}

- (NSView *)actionView {
  return sp_view;
}

- (id)sparkAction {
  return sp_action;
}

- (void)loadSparkAction:(SparkAction *)action toEdit:(BOOL)flag {
  // does nothing since name and icon are store in sp_action.
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  // Name should be check after 'configure action' to allow user to set it later.
  return nil;
}

- (void)configureAction {
  // does nothing
}

#pragma mark Notifications
- (void)pluginViewWillBecomeVisible {}
- (void)pluginViewDidBecomeVisible {}

- (void)pluginViewWillBecomeHidden {}
- (void)pluginViewDidBecomeHidden {}

#pragma mark Accessors
- (NSString *)name {
  return [sp_action name];
}

- (void)setName:(NSString *)name {
  [sp_action setName:name];
}

- (NSImage *)icon {
  return [sp_action icon];
}

- (void)setIcon:(NSImage *)icon {
  [sp_action setIcon:icon];
}

#pragma mark -
#pragma mark Private Methods
- (void)setSparkAction:(SparkAction *)action {
  [self willChangeValueForKey:@"name"];
  [self willChangeValueForKey:@"icon"];
  [self willChangeValueForKey:@"editable"];
  SKSetterRetain(sp_action, action);
  [self didChangeValueForKey:@"editable"];
  [self didChangeValueForKey:@"icon"];
  [self didChangeValueForKey:@"name"];
}
/* Called by Nib Loader only. Action view is a nib root object, so we should not retain it */
- (void)setActionView:(NSView *)actionView {
  sp_view = actionView;
  sp_sapFlags.ownership = 1;
}

- (void)releaseViewOwnership {
  /* If was ownership, release the view */
  if (sp_sapFlags.ownership) {
    [sp_view release];
    sp_sapFlags.ownership = 0;
  }
}

/* Compat */
- (NSUndoManager *)undoManager {
  return nil;
}

#pragma mark -
#pragma mark Plugin Informations
+ (Class)actionClass {
  Class actionClass = nil;
  NSBundle *bundle = SKCurrentBundle();
  NSString *class = [bundle objectForInfoDictionaryKey:@"SparkActionClass"];
  if (class && (actionClass = NSClassFromString(class)) ) {
    return actionClass;
  }
  [NSException raise:@"InvalidClassKeyException" format:@"Unable to find a valid class for key \"SparkActionClass\" in bundle \"%@\" propertylist", [bundle bundlePath]];
  return nil;
}

+ (NSString *)plugInName {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginName"];
  if (name) {
    return name;
  }
  [NSException raise:@"InvalidPlugInNameException" format:@"Unable to find a valid name for key \"SparkPlugInName\" in bundle \"%@\" propertylist", [bundle bundlePath]];
  return nil;
}

+ (NSImage *)plugInIcon {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginIcon"];
  NSImage *image = [NSImage imageNamed:name inBundle:bundle];
  if (!image) {
    image = [NSImage imageNamed:@"PluginIcon" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]];
  }
  return image;
}

 + (NSString *)helpFile {
  NSString *path = nil;
  NSBundle *bundle = SKCurrentBundle();
  NSString *help = [bundle objectForInfoDictionaryKey:@"SparkHelpFile"];
  if (help) {
    path = [bundle pathForResource:help ofType:nil];
    if (!path)
      path = [bundle pathForResource:help ofType:@"html"];
    if (!path)
      path = [bundle pathForResource:help ofType:@"htm"];
    if (!path)
      path = [bundle pathForResource:help ofType:@"rtf"];
    if (!path)
      path = [bundle pathForResource:help ofType:@"rtfd"];
  }
  return path;
}

+ (NSString *)nibPath {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"NSMainNibFile"];
  return name ? [bundle pathForResource:name ofType:@"nib"] : nil;
}

@end
