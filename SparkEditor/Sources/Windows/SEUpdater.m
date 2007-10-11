//
//  SEUpdater.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SEUpdater.h"

#include <unistd.h>

#import <ShadowKit/SKUpdater.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKThreadPort.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKProgressPanel.h>
#import <ShadowKit/SKUpdaterVersion.h>
#import <ShadowKit/SKCryptoFunctions.h>
#import <ShadowKit/SKUpdaterVersionWindow.h>

SKSingleton(SEUpdater, sharedUpdater);

@implementation SEUpdater

- (id)init {
  if (self = [super init]) {
    
  }
  return self;
}

- (void)dealloc {
  [se_size release];
  /* cancel will call delegate */
  [se_updater cancel:nil];
  [super dealloc];
}

- (void)runInBackground {
  if (!se_updater) {
    se_search = false;
    se_updater = [[SKUpdater alloc] initWithDelegate:self];
    [se_updater searchVersions:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL", @"SEUpdater", 
                                                                               @"URL of the update file (.xml or .plist).")] waitNetwork:YES];
  }
}

- (void)search {
  if (se_updater && [se_updater status] == kSKUpdaterWaitNetwork) {
    [se_updater cancel:nil];
  }
  /* set manual flags */
  se_search = true;
  se_updater = [[SKUpdater alloc] initWithDelegate:self];
  if (![se_updater searchVersions:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL", @"SEUpdater", 
                                                                                  @"URL of the update file (.xml or .plist).")] waitNetwork:NO]) {
    NSRunAlertPanel(@"Network unreachable", @"connect and retry", @"OK", nil, nil);
  }
}

#pragma mark Delegate
/* Required: Properties found */
- (void)updater:(SKUpdater *)updater didSearchVersions:(NSArray *)versions {
  SKUpdaterVersion *last = [versions lastObject];
  if (last) {
    if ([last version] > SKVersionGetCurrentNumber()) {
      se_version = [last version];
      SKUpdaterVersionWindow *dialog = [[SKUpdaterVersionWindow alloc] init];
      [dialog setVersions:versions];
      if (NSOKButton == [dialog runModal:YES]) {
        [updater downloadArchive:[last archiveForVersion:SKVersionGetCurrentNumber()]];
      } else {
        [se_updater release];
        se_updater = nil;
      }
    } else {
      /* if we are in manual mode */
      if (se_search)
        NSRunAlertPanel(@"Spark is up to date", @"you are using the last Spark version", @"OK", nil, nil);
      [se_updater release];
      se_updater = nil;
    }
  }
}

/* Update downloaded */
- (void)updater:(SKUpdater *)updater didDownloadArchive:(SKUpdaterArchive *)archive atPath:(NSString *)path {
  [se_progress stop];
  
  /* Check archive checksum */
  bool valid = true;
  if ([archive digest] && [archive digestAlgorithm]) {
    SKCryptoProvider csp;
    SKCryptoData digest = {0, NULL};
    SKCryptoResult res = SKCryptoCspAttach(&csp);
    if (CSSM_OK == res) {
      res = SKCryptoDigestFile(csp, [archive digestAlgorithm], [path fileSystemRepresentation], &digest);
      if (CSSM_OK == res && digest.Length == [[archive digest] length])
        valid = (0 == memcmp(digest.Data, [[archive digest] bytes], digest.Length));
      if (digest.Data)
        SKCDSAFree(csp, digest.Data);
      SKCryptoCspDetach(csp);
    }
  }
  if (!valid) 
    DLog(@"Invalid checksum");

  /* create SKPatch and apply */
//  /* create xar archive */  
//  se_archive = [[SKArchive alloc] initWithArchiveAtPath:path];
//  
//  [se_size release];
//  se_size = [[NSString localizedStringWithSize:[se_archive size] unit:@"B" precision:2] retain];
//  
//  FSRef bref;
//  NSString *bpath = [[NSBundle mainBundle] bundlePath];
//  NSString *base = [@"~/Desktop/" stringByStandardizingPath];
//  char tmp[255];
//  snprintf(tmp, 255, "%s-XXXXXXXX", getprogname());
//  NSString *str = [NSString stringWithFormat:@"%s", mktemp(tmp)];
//  
//  if ([bpath getFSRef:&bref]) {
//    FSVolumeRefNum volume;
//    OSStatus err = SKFSGetVolumeInfo(&bref, &volume, kFSVolInfoNone, NULL, NULL, NULL);
//    if (noErr == err)
//      base = [SKFSFindFolder(kTemporaryFolderType, volume, true) stringByAppendingPathComponent:str];
//  }
//  if (![[NSFileManager defaultManager] fileExistsAtPath:base])
//    SKFSCreateFolder((CFStringRef)base);
//  
//  [se_progress setTitle:@"Extracting archive"];
//  [se_progress setMaxValue:[se_archive size]];
//  [se_progress setValue:0];
//  [se_progress start];
//  [se_archive extractInBackgroundToPath:base handler:self];
  
  /* no longer need updater */
  [se_updater release];
  se_updater = nil;
}

- (void)updater:(SKUpdater *)updater didCancelOperation:(SKUpdaterStatus)status {
  ShadowTrace();
  [se_progress close:nil];
  [se_progress release];
  se_progress = nil;
  [se_updater release];
  se_updater = nil;
}

/* Required: Network unreachable or download failed */
- (void)updater:(SKUpdater *)updater errorOccured:(NSError *)anError duringOperation:(SKUpdaterStatus)theStatus {
  if (anError)
    [NSApp presentError:anError];
  
  [se_progress close];
  [se_progress release];
  se_progress = nil;
  
  [se_updater release];
  se_updater = nil;
}

/* Update download */
- (void)updater:(SKUpdater *)updater didStartDownloadArchive:(SKUpdaterArchive *)archive length:(SInt64)length {
  [self showProgressPanel];
  /* Set panel name */
  CFStringRef vers = SKVersionCreateStringForNumber(se_version);
  NSString *name = [NSString stringWithFormat:@"Downloading %@ v%@", 
    [[NSProcessInfo processInfo] processName], vers];
  if (vers) CFRelease(vers);
  [se_progress setTitle:name];
  
  if (NSURLResponseUnknownLength == length) {
    [se_progress setIndeterminate:YES];
  } else {
    [se_progress setIndeterminate:NO];
    [se_progress setMaxValue:length];
    
    [se_size release];
    se_size = [[NSString localizedStringWithSize:length unit:@"B" precision:2] retain];
  }
  [se_progress start];
}

- (void)updater:(SKUpdater *)updater downloadProgress:(SInt64)progress {
  [se_progress setValue:progress];
}

#pragma mark Human Interface
- (IBAction)cancel:(id)sender {
  if (se_updater)
    [se_updater cancel:nil];
}

- (void)showProgressPanel {
  if (!se_progress) {
    se_progress = [[SKProgressPanel alloc] init];
    [se_progress setDelegate:self];
    [se_progress setRefreshInterval:0.1];
    [se_progress setEvaluatesRemainingTime:NO];
  }
  [se_progress showWindow:nil];
}

- (void)progressPanelDidCancel:(SKProgressPanel *)aPanel {
  [self cancel:nil];
}

- (NSString *)progressPanel:(SKProgressPanel *)aPanel messageForValue:(double)value {
  NSString *size = [NSString localizedStringWithSize:value unit:@"B" precision:2];
  return [NSString stringWithFormat:@"%@ / %@", size, se_size];
}

//#pragma mark Archive
//- (void)archive:(SKArchive *)archive didProcessFile:(SKArchiveFile *)file path:(NSString *)fsPath {
//  UInt64 size = [file size];
//  if (size > 0)
//    [se_progress incrementBy:size];
//}
//
//- (void)archive:(SKArchive *)archive didExtract:(BOOL)result path:(NSString *)aPath {
//  [se_progress stop];
//  [se_progress close:nil];
//  [se_progress release];
//  se_progress = nil;
//  
//  DLog(@"End of extraction: %@", result ? @"YES" : @"NO");
//  
//  NSString *path = [archive path];
//  [archive autorelease];
//  [archive close];
//  se_archive = nil;
//  
//  FSRef fref;
//  if (noErr == FSPathMakeRef((const UInt8 *)[path UTF8String], &fref, NULL))
//    FSDeleteObject(&fref);
//  
//  [[NSWorkspace sharedWorkspace] openFile:aPath];
//}
//
//- (BOOL)archive:(SKArchive *)manager shouldProceedAfterError:(NSError *)anError {
//  DLog(@"%@", anError);
//  return YES;
//}

@end
