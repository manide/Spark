/*
 *  SparkAction.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"
#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkObjectSet.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKSerialization.h>

#define ICON_SIZE		16

static NSString * const kSparkActionFlagsKey = @"SAFlags";
static NSString * const kSparkActionVersionKey = @"SAVersion";
static NSString * const kSparkActionCategorieKey = @"SACategorie";
static NSString * const kSparkActionDescriptionKey = @"SADescription";

#pragma mark -
@implementation SparkAction

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  
  UInt32 flags = 0;
  if (sp_saFlags.invalid) flags |= 1 << 0;
  [coder encodeInt:flags forKey:kSparkActionFlagsKey];
  [coder encodeInt:sp_version forKey:kSparkActionVersionKey];
  if (nil != sp_categorie)
    [coder encodeObject:sp_categorie forKey:kSparkActionCategorieKey];
  if (nil != sp_description)
    [coder encodeObject:sp_description forKey:kSparkActionDescriptionKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    UInt32 flags = [coder decodeIntForKey:kSparkActionFlagsKey];
    if (flags & (1 << 0)) sp_saFlags.invalid = 1;
    sp_version = [coder decodeIntForKey:kSparkActionVersionKey];
    [self setCategorie:[coder decodeObjectForKey:kSparkActionCategorieKey]];
    [self setActionDescription:[coder decodeObjectForKey:kSparkActionDescriptionKey]];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkAction* copy = [super copyWithZone:zone];
  copy->sp_saFlags = sp_saFlags;
  copy->sp_version = sp_version;
  
  copy->sp_categorie = [sp_categorie retain];
  copy->sp_description = [sp_description retain];
  return copy;
}

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  if ([self version])
    [plist setObject:SKInt([self version]) forKey:kSparkActionVersionKey];
  
  if (nil != sp_description)
    [plist setObject:sp_description forKey:kSparkActionDescriptionKey];

  if (nil != sp_categorie)
    [plist setObject:sp_categorie forKey:kSparkActionCategorieKey];

  return YES;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    NSNumber *version = [plist objectForKey:kSparkActionVersionKey];
    if (!version)
      version = [plist objectForKey:@"Version"];
    [self setVersion:(version) ? [version intValue] : 0];
    
    NSString *description = [plist objectForKey:kSparkActionDescriptionKey];
    if (!description)
      description = [plist objectForKey:@"ShortDescription"];
    [self setActionDescription:description];
    
    /* Update categorie */
    SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] pluginForClass:[self class]];
    if (plugin && [plugin name]) {
      [self setCategorie:[plugin name]];
    } else {
      [self setCategorie:[plist objectForKey:kSparkActionCategorieKey]];
    }
  }
  return self;
}


#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self= [super init]) {
    id plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return self;
}

- (void)dealloc {
  [sp_description release];
  [sp_categorie release];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (SparkAlert *)actionDidLoad {
  if ([self respondsToSelector:@selector(check)])
    return [self performSelector:@selector(check)];
  return nil;
}

- (SparkAlert *)performAction {
  if ([self respondsToSelector:@selector(execute)])
    return [self performSelector:@selector(execute)];
  else
    NSBeep();
  return nil;
}

#pragma mark -
#pragma mark Accessors
- (void)setIcon:(NSImage *)icon {
  [super setIcon:SKResizedIcon(icon, NSMakeSize(ICON_SIZE, ICON_SIZE))];
}

- (UInt32)version {
  return sp_version;
}
- (void)setVersion:(UInt32)newVersion {
  sp_version = newVersion;
}

- (NSString *)categorie {
  if (!sp_categorie) {
    SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return sp_categorie;
}

- (NSString *)actionDescription {
  return sp_description;
}
- (void)setActionDescription:(NSString *)desc {
  SKSetterCopy(sp_description, desc);
}

- (NSTimeInterval)repeatInterval {
  return 0;
}

@end

#pragma mark -
@implementation SparkAction (Private)

- (id)duplicate {
  /* Copying fallback when instance does not implements copyWithZone: */
  id copy = nil;
  NSDictionary *plist = SKSerializeObject(self, NULL);
  if (plist)
    copy = SKDeserializeObject(plist, NULL);
  return copy;
}

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey {
  return [self performAction];
}

- (BOOL)isInvalid {
  return sp_saFlags.invalid;
}
- (void)setInvalid:(BOOL)flag {
  SKSetFlag(sp_saFlags.invalid, flag);
}

- (void)setCategorie:(NSString *)categorie {
  SKSetterCopy(sp_categorie, categorie);
}

/* Compatibility */
- (NSString *)shortDescription {
  return [self actionDescription];
}
- (void)setShortDescription:(NSString *)desc {
  [self setActionDescription:desc];
}

@end

#pragma mark -
@implementation SparkPlaceHolder (SparkAction)

- (NSString *)categorie {
  return [[self values] objectForKey:kSparkActionCategorieKey];
}
//- (void)setCategorie:(NSString *)categorie {}

- (NSString *)actionDescription {
  return NSLocalizedStringFromTableInBundle(@"Missing Plugin",
                                            nil, SKCurrentBundle(),
                                            @"Placeholder description");
}
- (void)setActionDescription:(NSString *)description {}

@end

