//
//  KGSinglePanePartitioning.m
//  Pugpig
//
//  Copyright (c) 2011, Kaldor Holdings Ltd.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer. Redistributions in binary form must reproduce
//  the above copyright notice, this list of conditions and the following disclaimer in
//  the documentation and/or other materials provided with the distribution.
//  Neither the name of pugpig nor the names of its contributors may be
//  used to endorse or promote products derived from this software without specific prior
//  written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
//  IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//  SUCH DAMAGE.
//

#import "KGSinglePanePartitioning.h"
#import "UIWebView+KGAdditions.h"

//==============================================================================
// MARK: - Private interface

@interface KGSinglePanePartitioning()

- (BOOL)scheduleSnapshotForPageNumber:(NSUInteger)page inWebView:(UIWebView*)webView orientation:(KGOrientation)orientation progressHandler:(void(^)(NSUInteger,BOOL))progress completionHandler:(void(^)(UIWebView*))completion;
- (void)takeSnapshotWithParms:(NSArray*)parms;
- (BOOL)interfaceOrientationMatchesOrientation:(KGOrientation)orientation;

@end

//==============================================================================
// MARK: - Main implementation

@implementation KGSinglePanePartitioning

@synthesize dataSource;
@synthesize imageStore;

//------------------------------------------------------------------------------
// MARK: NSObject messages

- (void)dealloc {
  [dataSource release];
  [imageStore release];
  [super dealloc];
}

//------------------------------------------------------------------------------
// MARK: Public messages and properties

- (NSUInteger)numberOfPanesInOrientation:(KGOrientation)orientation {
  return [dataSource numberOfPages];
}

- (NSInteger)pageForPaneNumber:(NSUInteger)pane orientation:(KGOrientation)orientation {
  return pane;
}

- (NSInteger)paneForPageNumber:(NSUInteger)page orientation:(KGOrientation)orientation {
  return page;
}

- (CGRect)frameForPageNumber:(NSUInteger)page pageSize:(CGSize)size orientation:(KGOrientation)orientation {
  return CGRectMake(page*size.width, 0, size.width, size.height);
}

- (BOOL)layoutWebView:(UIWebView*)webView pageSize:(CGSize)size orientation:(KGOrientation)orientation {
  return NO;
}

- (void)takeSnapshotsForWebView:(UIWebView*)webView pageSize:(CGSize)size orientation:(KGOrientation)orientation progressHandler:(void(^)(NSUInteger,BOOL))progress completionHandler:(void(^)(UIWebView*))completion {
  BOOL scheduled = NO;
  NSInteger page = [webView tag];
  if (page >= 0 && page < [dataSource numberOfPages]) {
    // Check that the current interfaceOrientation still matches the 
    // orientation at which the page was rendered otherwise the rendering 
    // won't be completely correct and the snapshot image won't match the 
    // final rendering.
    if ([self interfaceOrientationMatchesOrientation:orientation])
      scheduled = [self scheduleSnapshotForPageNumber:page inWebView:webView orientation:orientation progressHandler:progress completionHandler:completion];
  }    
  if (!scheduled) completion(webView);
}

- (BOOL)hasSnapshotsForPageNumber:(NSUInteger)page orientation:(KGOrientation)orientation {
  NSString *variant = [NSString stringWithFormat:@"%d",orientation];
  return [imageStore hasImageForPageNumber:page variant:variant];
}

- (UIImage*)snapshotForPaneNumber:(NSUInteger)pane orientation:(KGOrientation)orientation withOptions:(KGImageStoreOptions)options {
  NSString *variant = [NSString stringWithFormat:@"%d",orientation];
  if ([imageStore respondsToSelector:@selector(imageForPageNumber:variant:withOptions:)])
    return [imageStore imageForPageNumber:pane variant:variant withOptions:options];
  else  
    return [imageStore imageForPageNumber:pane variant:variant];
}

- (void)resetPageNumber:(NSUInteger)page {
}

- (void)resetAllPages {
}

- (NSInteger)paneFromFragment:(NSString*)fragment inWebView:(UIWebView*)webView pageSize:(CGSize)size orientation:(KGOrientation)orientation {
  return -1;
}

- (CGFloat)fractionalPageFromPane:(CGFloat)pane orientation:(KGOrientation)orientation {
  return pane;
}

- (id)persistentStateForPaneNumber:(NSUInteger)pane orientation:(KGOrientation)orientation {
  return [NSNumber numberWithUnsignedInteger:pane];
}

- (NSUInteger)paneFromPersistentState:(id)state orientation:(KGOrientation)orientation {
  return [(NSNumber*)state unsignedIntegerValue];
}

//------------------------------------------------------------------------------
// MARK: Private messages

- (BOOL)scheduleSnapshotForPageNumber:(NSUInteger)page inWebView:(UIWebView*)webView orientation:(KGOrientation)orientation progressHandler:(void(^)(NSUInteger,BOOL))progress completionHandler:(void(^)(UIWebView*))completion {
  NSString *variant = [NSString stringWithFormat:@"%d",orientation];
  if (![imageStore hasImageForPageNumber:page variant:variant]) {
    progress(0,NO);
    NSArray *parms = [NSArray arrayWithObjects:webView,
      [NSNumber numberWithUnsignedInteger:orientation],
      [NSNumber numberWithUnsignedInteger:page],
      [[progress copy] autorelease],
      [[completion copy] autorelease],nil];
    [self performSelector:@selector(takeSnapshotWithParms:) withObject:parms afterDelay:0.0];
    return YES;
  }
  return NO;
}

- (void)takeSnapshotWithParms:(NSArray*)parms {
  UIWebView *webView = [parms objectAtIndex:0];
  KGOrientation orientation = [[parms objectAtIndex:1] unsignedIntegerValue];
  NSUInteger page = [[parms objectAtIndex:2] unsignedIntegerValue];
  void(^progress)(NSUInteger,BOOL) = [parms objectAtIndex:3];
  void(^completion)(UIWebView*) = [parms objectAtIndex:4];
  BOOL scheduled = NO;

  // Check that the webView hasn't been killed since we scheduled
  // this snapshot.
  if (webView.tag == page) {
    // Check that the current interfaceOrientation still matches the 
    // orientation at which the page was rendered.
    if ([self interfaceOrientationMatchesOrientation:orientation]) {
      UIImage *snapShot = [webView getImageFromView];
      NSString *variant = [NSString stringWithFormat:@"%d",orientation];
      [imageStore saveImage:snapShot forPageNumber:page variant:variant];
      progress(0,YES);
      scheduled = [self scheduleSnapshotForPageNumber:page inWebView:webView orientation:orientation progressHandler:progress completionHandler:completion];
    }
  }
  
  if (!scheduled) completion(webView);
}

- (BOOL)interfaceOrientationMatchesOrientation:(KGOrientation)orientation {
  UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
  return (
    (UIInterfaceOrientationIsLandscape(interfaceOrientation) && orientation == KGLandscapeOrientation) ||
    (UIInterfaceOrientationIsPortrait(interfaceOrientation) && orientation == KGPortraitOrientation)
  );
}

@end
