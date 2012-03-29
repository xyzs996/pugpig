//
//  KGPagedDocControl.m
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

#import "KGPagedDocControl.h"
#import "KGPagedDocControlImplementation.h"

@implementation KGPagedDocControl

@dynamic delegate;
@dynamic paneManager;
@dynamic imageStore;
@dynamic dataSource;
@dynamic navigator;
@dynamic numberOfPanes;
@dynamic numberOfPages;
@dynamic paneNumber;
@dynamic pageNumber;
@dynamic fractionalPaneNumber;
@dynamic fractionalPageNumber;
@dynamic currentPageView;
@dynamic scale;
@dynamic scrollEnabled;
@dynamic fragmentNavigationAnimated;
@dynamic fragmentScrollOffset;
@dynamic mediaPlaybackRequiresUserAction;
@dynamic linksOpenInExternalBrowser;
@dynamic bounces;

+ (id)alloc {
  if ([self isEqual:[KGPagedDocControl class]])
    return (KGPagedDocControl*)[KGPagedDocControlImplementation alloc];
  else
    return [super alloc];
}

- (void)hideUntilInitialised {
  // implemented in KGPagedDocControlImplementation
}

- (void)hideUntilInitialised:(NSUInteger)requiredPages {
  // implemented in KGPagedDocControlImplementation
}

- (void)setPaneNumber:(NSUInteger)newPaneNumber animated:(BOOL)animated {
  // implemented in KGPagedDocControlImplementation
}

- (void)setPageNumber:(NSUInteger)newPageNumber animated:(BOOL)animated {
  // implemented in KGPagedDocControlImplementation
}

- (BOOL)moveToPageURL:(NSURL*)url animated:(BOOL)animated {
  // implemented in KGPagedDocControlImplementation
  return NO;
}

- (id)savePosition {
  // implemented in KGPagedDocControlImplementation
  return nil;
}

- (void)restorePosition:(id)position {
  // implemented in KGPagedDocControlImplementation
}

- (void)refreshCurrentPage {
  // implemented in KGPagedDocControlImplementation
}

- (void)refreshContentSize {
  // implemented in KGPagedDocControlImplementation
}

- (void)startSnapshotting {
  // implemented in KGPagedDocControlImplementation
}

- (void)stopSnapshotting {
  // implemented in KGPagedDocControlImplementation
}

- (NSString*)stringByEvaluatingScript:(NSString*)script {
  // implemented in KGPagedDocControlImplementation
  return nil;
}

- (KGOrientation)orientationForSize:(CGSize)size {
  return (size.width > size.height ? KGLandscapeOrientation : KGPortraitOrientation);
}

@end
