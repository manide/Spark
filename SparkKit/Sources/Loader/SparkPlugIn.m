/*
 *  SparkPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionLoader.h>

NSString * const SparkPlugInDidChangeStatusNotification = @"SparkPlugInDidChangeStatus";

@implementation SparkPlugIn

/* Check status */
static 
BOOL SparkPlugInIsEnabled(NSString *identifier, BOOL *exists) {
  BOOL enabled = YES;
  if (exists) *exists = NO;
  NSDictionary *plugins = SparkPreferencesGetValue(@"SparkPlugIns", SparkPreferencesFramework);
  if (plugins) {
    NSNumber *status = [plugins objectForKey:identifier];
    if (status) {
      if (exists) *exists = YES;
      enabled = [status boolValue];
    }
  }
  return enabled;
}

static 
void SparkPlugInSetEnabled(NSString *identifier, BOOL enabled) {
  if (SparkGetCurrentContext() == kSparkEditorContext) {
    NSMutableDictionary *plugins = NULL;
    NSDictionary *prefs = SparkPreferencesGetValue(@"SparkPlugIns", SparkPreferencesFramework);
    if (!prefs) {
      plugins = [[NSMutableDictionary alloc] init];
    } else {
      plugins = [prefs mutableCopy];
    }
    [plugins setObject:WBBool(enabled) forKey:identifier];
    SparkPreferencesSetValue(@"SparkPlugIns", plugins, SparkPreferencesFramework);
    [plugins release];
  }
}

/* Synchronize daemon */
+ (void)setFrameworkValue:(NSDictionary *)plugins forKey:(NSString *)key {
  NSString *identifier;
  NSEnumerator *keys = [plugins keyEnumerator];
  SparkActionLoader *loader = [SparkActionLoader sharedLoader];
  while (identifier = [keys nextObject]) {
    SparkPlugIn *plugin = [loader plugInForIdentifier:identifier];
    if (plugin) {
      NSNumber *value = [plugins objectForKey:identifier];
      if (value && [value respondsToSelector:@selector(boolValue)])
        [plugin setEnabled:[value boolValue]];
    }
  }
}

+ (void)initialize {
  if ([SparkPlugIn class] == self) {
    if (SparkGetCurrentContext() == kSparkDaemonContext) {
      SparkPreferencesRegisterObserver(self, @selector(setFrameworkValue:forKey:), @"SparkPlugIns", SparkPreferencesFramework);
    }
  }
}

- (id)init {
  if (self = [super init]) {
    // Should not create valid plugin with this method.
  }
  return self;
}

- (id)initWithClass:(Class)cls identifier:(NSString *)identifier {
  if (![cls isSubclassOfClass:[SparkActionPlugIn class]]) {
    [self release];
    WBThrowException(NSInvalidArgumentException, @"Invalid action plugin class.");
  } 
  
  if (self = [super init]) {
    sp_class = cls;
    [self setIdentifier:identifier];
    
    [self setVersion:[cls versionString]];
    
    /* Set status */
    BOOL exists;
    BOOL status = SparkPlugInIsEnabled(identifier, &exists);
    if (exists)
      WBFlagSet(sp_spFlags.disabled, !status);
    else
      WBFlagSet(sp_spFlags.disabled, ![sp_class isEnabled]);
  }
  return self;
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [self initWithClass:[bundle principalClass]
                      identifier:[bundle bundleIdentifier]]) {
    [self setPath:[bundle bundlePath]];
    
    /* Extend applescript support */
//    if (SparkGetCurrentContext() == kSparkEditorContext)
//      [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
  }
  return self;
}

- (void)dealloc {
  [sp_nib release];
  [sp_name release];
  [sp_path release];
  [sp_icon release];
  [sp_version release];
  [sp_identifier release];
  [super dealloc];
}

- (NSUInteger)hash {
  return [sp_identifier hash];
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:[SparkPlugIn class]])
    return NO;
  
  return [sp_identifier isEqual:[object identifier]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@, Class: %@, Status: %@}",
    [self class], self,
    [self name], sp_class,
    ([self isEnabled] ? @"On" : @"Off")];
}

#pragma mark -
- (NSString *)name {
  if (sp_name == nil) {
    [self setName:[sp_class plugInName]];
  }
  return sp_name;
}
- (void)setName:(NSString *)newName {
  WBSetterRetain(&sp_name, newName);
}

- (NSString *)path {
  return sp_path;
}

- (void)setPath:(NSString *)newPath {
  WBSetterRetain(&sp_path, newPath);
}

- (NSImage *)icon {
  if (sp_icon == nil) {
    [self setIcon:[sp_class plugInIcon]];
  }
  return sp_icon;
}
- (void)setIcon:(NSImage *)icon {
  WBSetterRetain(&sp_icon, icon);
}

- (BOOL)isEnabled {
  return !sp_spFlags.disabled;
}
- (void)setEnabled:(BOOL)flag {
  bool disabled = WBFlagTestAndSet(sp_spFlags.disabled, !flag);
  /* If status change */
  if (disabled != sp_spFlags.disabled) {
    /* Update preferences */
    SparkPlugInSetEnabled([self identifier], flag);
    [[NSNotificationCenter defaultCenter] postNotificationName:SparkPlugInDidChangeStatusNotification
                                                        object:self];
    
  }
}

- (NSBundle *)bundle {
  NSBundle *bundle = nil;
  if ([self path])
    bundle = [NSBundle bundleWithPath:[self path]];
  if (!bundle)
    bundle = [NSBundle bundleForClass:sp_class];
  if (bundle != [NSBundle mainBundle]) return bundle;
  return nil;
}

- (NSString *)version {
  if (!sp_version) {
    // Try to init version
    sp_version = [[[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] retain];
  }
  return sp_version;
}
- (void)setVersion:(NSString *)version {
  WBSetterCopy(&sp_version, version);
}

- (NSString *)identifier {
  return sp_identifier;
}
- (void)setIdentifier:(NSString *)identifier {
  WBSetterRetain(&sp_identifier, identifier);
}

- (NSURL *)helpURL {
  NSString *help = [sp_class helpFile];
  if (help)
    return [NSURL fileURLWithPath:help];
  return nil;
}
- (NSString *)sdefFile {
  NSBundle *bundle = [self bundle];
  if (bundle) {
    NSString *sdef = [bundle objectForInfoDictionaryKey:@"OSAScriptingDefinition"];
    if (sdef) {
      return [bundle pathForResource:[sdef stringByDeletingPathExtension] ofType:[sdef pathExtension]];
    }
  }
  return nil;
}

- (id)instantiatePlugIn {
  if (!sp_nib) {
    NSString *path = [sp_class nibPath];
    if (path) {
      NSURL *url = [NSURL fileURLWithPath:path];
      sp_nib = [[NSNib alloc] initWithContentsOfURL:url];
    } else {
      sp_nib = [NSNull null];
      DLog(@"Plugin does not have nib path");
    }
  }
  SparkActionPlugIn *plugin = [[sp_class alloc] init];
  if (sp_nib != [NSNull null]) 
    [sp_nib instantiateNibWithOwner:plugin topLevelObjects:nil];
  return [plugin autorelease];
}

- (Class)plugInClass {
  return sp_class;
}
- (Class)actionClass {
  return [sp_class actionClass];
}


/* Growl Support */

static NSDictionary *_SparkLocalizeDictionaryValues(NSDictionary *base, NSBundle *bundle, NSString *table) {
  if (!base) return nil;
  
  NSString *key;
  NSEnumerator *keys = [base keyEnumerator];
  NSMutableDictionary *localized = [NSMutableDictionary dictionary];
  while (key = [keys nextObject]) {
    NSString *value = [base objectForKey:key];
    NSString *localization = [bundle localizedStringForKey:value value:nil table:table];
    if (localization) [localized setObject:localization forKey:key];
    else  [localized setObject:value forKey:key];
  }
  return localized;
}

- (NSDictionary *)growlNotifications {
  NSBundle *bundle = [self bundle];
  NSDictionary *dict = [sp_class growlNotifications];
  if (!dict) {
    NSString *plist = [bundle pathForResource:@"GrowlNotifications" ofType:@"plist"];
    if (plist)
      dict = [NSDictionary dictionaryWithContentsOfFile:plist];
  }
  /* localize dictionary */
  if (dict) {
    if ([bundle pathForResource:@"GrowlNotifications" ofType:@"strings"]) {
      NSDictionary *names = _SparkLocalizeDictionaryValues([dict objectForKey:@"HumanReadableNames"], bundle, @"GrowlNotifications");
      NSDictionary *descriptions = _SparkLocalizeDictionaryValues([dict objectForKey:@"NotificationDescriptions"], bundle, @"GrowlNotifications");
      if (names || descriptions) {
        NSMutableDictionary *tmp = [[dict mutableCopy] autorelease];
        if (names)
          [tmp setObject:names forKey:@"HumanReadableNames"];
        if (descriptions)
          [tmp setObject:descriptions forKey:@"NotificationDescriptions"];
        dict = tmp;
      }
    }
  }
  return dict;
}

@end

