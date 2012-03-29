//
//  KGPagedDocControlImplementation.m
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

#import "KGPagedDocControlImplementation.h"
#import "KGInMemoryImageStore.h"
#import "KGSinglePanePartitioning.h"
#import "KGCappedScrollView.h"
#import "KGStartupView.h"
#import "KGBrowserViewController.h"
#import "KGControlEvents.h"
#import "UIWebView+KGAdditions.h"

//==============================================================================
// MARK: - Private interface

@interface KGPagedDocControlImplementation()

@property (nonatomic, retain) KGStartupView *startupView;
@property (nonatomic, retain) KGCappedScrollView *scrollView;
@property (nonatomic, retain) UIWebView *mainWebView, *backgroundWebView;
@property (nonatomic, retain) UIImageView *leftImageView, *rightImageView, *centreImageView;
@property (nonatomic, retain) UIActivityIndicatorView *leftBusyView, *rightBusyView, *centreBusyView;
@property (nonatomic, assign) BOOL delayedLayoutChange;
@property (nonatomic, copy) NSString *targetFragment;
@property (nonatomic, assign) NSUInteger targetFragmentPage;
@property (nonatomic, assign) BOOL scrollViewAnimating;

- (void)initControl;
- (BOOL)interfaceOrientationMatchesOrientation:(KGOrientation)orientation;
- (void)updateFractionalPosition;
- (CGRect)frameForPaneNumber:(NSUInteger)pane;
- (CGRect)frameForPageNumber:(NSUInteger)page;
- (void)createScrollView;
- (void)repositionAfterLayoutChange;
- (UIImageView*)createImageView;
- (UIActivityIndicatorView*)createBusyView;
- (void)preloadImageViewsForJumpFromPane:(NSInteger)start toPane:(NSInteger)end;
- (void)resetImageViewsForPageNumber:(NSUInteger)page offset:(NSUInteger)offset orientation:(KGOrientation)orientation;
- (void)positionImageViewsCentredOnPane:(NSInteger)pane;
- (void)positionImageView:(UIImageView*)imageView andBusyView:(UIActivityIndicatorView*)busyView forPane:(NSInteger)pane;
- (UIWebView*)createWebViewWithSize:(CGSize)size;
- (void)stopWebView:(UIWebView*)webView;
- (void)initWebView:(UIWebView*)webView withDataSourcePageNumber:(NSUInteger)page foreground:(BOOL)foreground;
- (void)webView:(UIWebView*)webView didFinish:(KGPagedDocFinishedMask)finished;
- (void)webView:(UIWebView*)webView didFinishPageNumber:(NSUInteger)page pageSize:(CGSize)size foreground:(BOOL)foreground;
- (BOOL)webViewHasJavascriptDelay:(UIWebView*)webView;
- (NSString*)metaTag:(NSString*)tagName forWebView:(UIWebView*)webView;
- (void)loadMainWebView;
- (void)showMainWebView;
- (void)callbackMainWebViewAfterSnapshot;
- (void)scrollMainWebViewToFragment:(NSString*)fragment;
- (void)setMainWebViewFragment:(NSString*)fragment;
- (void)moveToPaneWithFragment:(NSString*)fragment;
- (void)startSnapshottingAfterDelay:(CGFloat)delay;
- (void)stopSnapshottingAndRestartAfterDelay:(CGFloat)delay;
- (void)loadBackgroundWebViews;
- (BOOL)loadBackgroundWebViewsWithOrientation:(KGOrientation)orientation size:(CGSize)size;
- (BOOL)loadBackgroundWebViewsForPageNumber:(NSInteger)page withOrientation:(KGOrientation)orientation size:(CGSize)size;
- (void)updateNavigatorDataSource;
- (void)navigatorPageChanged;
- (void)preloadImagesForCurrentPane;
- (void)preloadImagesForPane:(NSUInteger)pane;
- (void)preloadImageForPane:(NSInteger)pane inRange:(NSRange)range;
- (void)startupUpdateProgress:(BOOL)afterSnapshot;
- (NSUInteger)startupPagesInitialised;
- (UIView*)isSelfOrChildFirstResponder:(UIView*)rootView;
- (UIViewController*)firstAvailableViewControllerForView:(UIView*)view;
- (void)sendActionsForControlEvent:(KGControlEvents)event from:(id)sender;
- (BOOL)reportDidClickLink:(NSURL*)URL;
- (void)reportDidExecuteCommand:(NSURL*)URL;

@end

//==============================================================================
// MARK: - Main implementation

@implementation KGPagedDocControlImplementation

@synthesize delegate;
@synthesize paneManager;
@synthesize imageStore;
@synthesize dataSource;
@synthesize navigator;
@dynamic numberOfPanes;
@synthesize numberOfPages;
@synthesize paneNumber;
@synthesize pageNumber;
@synthesize fractionalPaneNumber;
@synthesize fractionalPageNumber;
@synthesize currentPageView;
@synthesize scale;
@synthesize scrollEnabled;
@synthesize fragmentNavigationAnimated;
@synthesize fragmentScrollOffset;
@synthesize mediaPlaybackRequiresUserAction;
@synthesize linksOpenInExternalBrowser;
@dynamic bounces;

@synthesize startupView;
@synthesize scrollView;
@synthesize mainWebView, backgroundWebView;
@synthesize leftImageView, rightImageView, centreImageView;
@synthesize leftBusyView, rightBusyView, centreBusyView;
@synthesize delayedLayoutChange;
@synthesize targetFragment;
@synthesize targetFragmentPage;
@synthesize scrollViewAnimating;

//------------------------------------------------------------------------------
// MARK: NSObject/UIView messages

- (id)initWithFrame:(CGRect)aRect {
  self = [super initWithFrame:aRect];
  if (self) {
    [self initControl];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self initControl];
  }
  return self;
}

- (void)dealloc {
  [paneManager release];
  [imageStore release];
  [dataSource release];
  [navigator release];
  
  [startupView release];
  [scrollView release];
  [mainWebView release];
  [backgroundWebView release];
  [leftImageView release];
  [rightImageView release];
  [centreImageView release];
  [leftBusyView release];
  [rightBusyView release];
  [centreBusyView release];
  [targetFragment release];
  
  [super dealloc];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (!CGSizeEqualToSize(lastLayoutSize, self.bounds.size)) {
    lastLayoutSize = self.bounds.size;
    if ([scrollView isDecelerating] || [scrollView isDragging])
      delayedLayoutChange = YES;
    else  
      [self repositionAfterLayoutChange];
  }
}

//------------------------------------------------------------------------------
// MARK: Public messages and properties

- (void)hideUntilInitialised {
  [self hideUntilInitialised:INT_MAX];
}

- (void)hideUntilInitialised:(NSUInteger)requiredPages {
  startupRequiredPages = MIN(requiredPages, numberOfPages);
  if ([self startupPagesInitialised] < startupRequiredPages)
    self.startupView = [[[KGStartupView alloc] init] autorelease];
}

- (void)setPaneManager:(id<KGDocumentPaneManagement>)newPaneManager {
  if (paneManager != newPaneManager) {
    [paneManager release];
    paneManager = [newPaneManager retain];
    
    [paneManager setImageStore:imageStore];
    [paneManager setDataSource:dataSource];
  }
}

- (void)setImageStore:(id<KGDocumentImageStore>)newImageStore {
  if (imageStore != newImageStore) {
    [imageStore release];
    imageStore = [newImageStore retain];
    
    [paneManager setImageStore:imageStore];
    
    [self updateNavigatorDataSource];
    // TODO: rebuild cache if datasource already set?
  }
}

- (void)setDataSource:(id<KGDocumentDataSource>)newDataSource {
  if (dataSource != newDataSource) {
    [dataSource release];
    dataSource = [newDataSource retain];
    numberOfPages = [dataSource numberOfPages];
    
    [paneManager setDataSource:dataSource];
    
    paneNumber = -1;
    pageNumber = -1;
    mainWebView.tag = -1;
    
    [self updateNavigatorDataSource];
    [self refreshContentSize];
    [self stopSnapshotting];
    [self startSnapshotting];
    
    // Note that we no longer automatically set the page number to zero here.
    // It's up to the calling code to explicitly set the page number after 
    // setting the datasource. This avoids the page number being set twice 
    // (which can be fairly expensive) when the caller wants to start on a 
    // page other than zero.
  }
}

- (void)setNavigator:(UIControl<KGPagedDocControlNavigator>*)newNavigator {
  if (navigator != newNavigator) {
    [navigator removeTarget:self action:@selector(navigatorPageChanged) forControlEvents:UIControlEventValueChanged];
    [navigator release];
    navigator = [newNavigator retain];
    [navigator addTarget:self action:@selector(navigatorPageChanged) forControlEvents:UIControlEventValueChanged];
    
    [self updateNavigatorDataSource];
    
    navigator.pageOrientation = currentOrientation;
    navigator.fractionalPageNumber = fractionalPageNumber;
  }
}

- (NSUInteger)numberOfPanes {
  return [paneManager numberOfPanesInOrientation:currentOrientation];
}

- (void)setPaneNumber:(NSUInteger)newPaneNumber {
  [self setPaneNumber:newPaneNumber animated:NO];
}

- (void)setPaneNumber:(NSUInteger)newPaneNumber animated:(BOOL)animated {
  NSUInteger newPageNumber = [paneManager pageForPaneNumber:newPaneNumber orientation:currentOrientation];
  if (newPageNumber == pageNumber && newPaneNumber == paneNumber) return;
  
  if (newPageNumber != targetFragmentPage) {
    [self setTargetFragment:nil];
    [self setTargetFragmentPage:0];
  }
  
  if (animated) {
    // If the main web view is offscreen (i.e. it's still loading), we stop
    // it and delete it so that it doesn't slow down the animation.
    if (mainWebView.frame.origin.y > 1024 && newPageNumber != pageNumber) {
      [self stopWebView:mainWebView];
      [mainWebView removeFromSuperview];
      self.currentPageView = nil;
      self.mainWebView = nil;
    }
    // Also cancel any background loads temporarily.
    [self stopSnapshottingAndRestartAfterDelay:1.0];
    // We return after initiating the scroll animation since setPaneNumber
    // will be called again once the animation is complete.
    [self preloadImageViewsForJumpFromPane:paneNumber toPane:newPaneNumber];
    CGRect rect = [self frameForPaneNumber:newPaneNumber];
    [scrollView scrollRectToVisible:rect animated:YES];
    return;
  }

  if (paneNumber != newPaneNumber) {
    [self willChangeValueForKey:@"paneNumber"];
    paneNumber = newPaneNumber;
    [self didChangeValueForKey:@"paneNumber"];
    CGRect rect = [self frameForPaneNumber:newPaneNumber];
    [scrollView scrollRectToVisible:rect animated:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(preloadImagesForCurrentPane) object:nil];
    [self performSelector:@selector(preloadImagesForCurrentPane) withObject:nil afterDelay:0];
  }
    
  if (pageNumber != newPageNumber) {
    [self willChangeValueForKey:@"pageNumber"];
    pageNumber = newPageNumber;
    [self didChangeValueForKey:@"pageNumber"];
    navigator.pageNumber = newPageNumber;
    refreshScrollPosition = CGPointZero;
    [self loadMainWebView];
  }
  
  [self positionImageViewsCentredOnPane:paneNumber];
  [self showMainWebView];
  [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setPageNumber:(NSUInteger)newPageNumber {
  [self setPageNumber:newPageNumber animated:NO];
}

- (void)setPageNumber:(NSUInteger)newPageNumber animated:(BOOL)animated {
  NSUInteger newPaneNumber = [paneManager paneForPageNumber:newPageNumber orientation:currentOrientation];
  [self setPaneNumber:newPaneNumber animated:animated];
}

- (BOOL)moveToPageURL:(NSURL*)url animated:(BOOL)animated {
  NSInteger page = [dataSource pageNumberForURL:url];
  if (page == -1) return NO;
  NSString *fragment = [url fragment];
  if (page == pageNumber) {
    [self setMainWebViewFragment:fragment];
    [self moveToPaneWithFragment:fragment];
    [self scrollMainWebViewToFragment:fragment];
  }
  else {
    [self setTargetFragment:fragment];
    [self setTargetFragmentPage:page];
    [self setPageNumber:page animated:animated];
  }
  return YES;
}

- (void)setScrollEnabled:(BOOL)newScrollEnabled {
  if (scrollEnabled != newScrollEnabled) {
    scrollEnabled = newScrollEnabled;
    mainWebView.scrollEnabled = newScrollEnabled;
  }
}

- (void)setMediaPlaybackRequiresUserAction:(BOOL)newValue {
  if (mediaPlaybackRequiresUserAction != newValue) {
    mediaPlaybackRequiresUserAction = newValue;
    mainWebView.mediaPlaybackRequiresUserAction = mediaPlaybackRequiresUserAction;
  }
}

- (BOOL)bounces {
  return [scrollView bounces];
}

- (void)setBounces:(BOOL)bounces {
  [scrollView setBounces:bounces];
}

- (void)setOpaque:(BOOL)opaque {
  [super setOpaque:opaque];
  [scrollView setOpaque:opaque];
  [mainWebView setOpaque:opaque];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [super setBackgroundColor:backgroundColor];
  [scrollView setBackgroundColor:backgroundColor];
  [mainWebView setBackgroundColor:backgroundColor];
}

- (id)savePosition {
  return [paneManager persistentStateForPaneNumber:paneNumber orientation:currentOrientation];
}

- (void)restorePosition:(id)position {
  if (position) [self setPaneNumber:[paneManager paneFromPersistentState:position orientation:currentOrientation]];
}

- (void)refreshCurrentPage {
  // TODO: see if we can make this refresh smoother
  UIScrollView *webScrollView = [[mainWebView subviews] lastObject];
  refreshScrollPosition = [webScrollView contentOffset];
  self.mainWebView.tag = -1;
  [self loadMainWebView];
}

- (void)refreshContentSize {
  NSUInteger panes = [self numberOfPanes];
  if (panes) {
    CGSize size = self.bounds.size;
    [scrollView setContentSize:CGSizeMake(panes * size.width, size.height)];
    [self sendActionsForControlEvent:KGControlEventContentSizeChanged from:self];
  }
}

- (void)startSnapshotting {
  // If we start the background load immediately it sometimes doesn't
  // snapshot properly for the first page.
  [self startSnapshottingAfterDelay:0.5];
}

- (void)stopSnapshotting {
  if (backgroundBusyLoading) {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadBackgroundWebViews) object:nil];
    
    [self stopWebView:backgroundWebView];
    [backgroundWebView removeFromSuperview];
    self.backgroundWebView = nil;
    
    backgroundBusyLoading = NO;
  }  
}

- (NSString*)stringByEvaluatingScript:(NSString*)script {
  return [mainWebView stringByEvaluatingJavaScriptFromString:script];
}

//------------------------------------------------------------------------------
// MARK: UIResponder messages

// TODO: do we need to handle the other responder messages so that this
// makes proper sense?

- (BOOL)isFirstResponder {
  return mainWebView && [self isSelfOrChildFirstResponder:mainWebView];
}

//------------------------------------------------------------------------------
// MARK: UIScrollViewDelegate messages

- (void)scrollViewWillBeginDragging:(UIScrollView *)sender {
  [self setScrollViewAnimating:NO];
  [scrollView setMaxDelta:100.0];
  // Cancel any background loads temporarily so we have smoother dragging.
  [self stopSnapshottingAndRestartAfterDelay:1.0];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
  [self updateFractionalPosition];
  
  navigator.fractionalPageNumber = fractionalPageNumber;
  NSInteger newPaneNumber = round(fractionalPaneNumber);
  
  [self positionImageViewsCentredOnPane:newPaneNumber];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)sender {
  if (delayedLayoutChange) {
    // This cancels the deceleration, since the page is ultimately going
    // to be repositioned once the delayed layout change kicks in.
    if (scrollView.contentOffset.x >= 0)
      [sender setContentOffset:sender.contentOffset animated:NO];
  }  
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender {
  [self setScrollViewAnimating:NO];
  [self updateFractionalPosition];
  navigator.fractionalPageNumber = fractionalPageNumber;
  NSInteger destPaneNum = round(fractionalPaneNumber);
  
  [scrollView setMaxDelta:0.0];
  if (delayedLayoutChange) {
    // We can't reposition the scroll view from within the didEndDeclerating
    // callback, so we need to add this code to the dispatch queue to be run
    // later.
    dispatch_async(dispatch_get_main_queue(), ^{
      // We set the pane number here so that the position that is restored
      // after the layout change is closer to where we currently are rather
      // than the initial start point.
      paneNumber = destPaneNum;
      [self repositionAfterLayoutChange];
      delayedLayoutChange = NO;
    });    
  }  
  else {  
    [self setPaneNumber:destPaneNum];
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sender {
  [scrollView setMaxDelta:0.0];
  [self updateFractionalPosition];
  navigator.fractionalPageNumber = fractionalPageNumber;
  NSInteger destPaneNum = round(fractionalPaneNumber);
  [self setPaneNumber:destPaneNum];
}

//------------------------------------------------------------------------------
// MARK: UIWebViewDelegate messages

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
  NSURL *URL = [request URL];
  BOOL shouldStart = YES;
  NSString *scheme = [URL scheme];
  BOOL isPlumbSchema = [scheme isEqualToString:@"pugpig"];
  if (isPlumbSchema) {
    NSString *plumbCommand = [URL host];
    if ([plumbCommand isEqualToString:@"onPageReady"])
      [self webView:webView didFinish:KGPDFinishedJS];
    else
      [self reportDidExecuteCommand:URL];
    shouldStart = NO;
  }
  else if (webView == mainWebView && webView.request != nil) {
    // At this point, we want to be able to trap any clicked links so we can 
    // potentially open them in our internal browser, or an external instance 
    // of Safari. In most cases we just need to look for requests with the 
    // "LinkClicked" navigation type but this doesn't take into account clicks 
    // that are initiated via javascript which show up as the "Other" navigation 
    // type, so we need to intercept those too. However, we can't just intercept
    // all "Other" requests, because that would included IFRAMEs which we 
    // definitely don't want to intercept. Our solution is to check the web 
    // view's isLoading property: if it's still loading, we assume the request 
    // is for an IFRAME; if not, we treat it as a clicked link.
    
    // TODO: Maybe we can do a better job of this test using some combination 
    // of webView.request vs request and request.mainDocumentURL vs URL.
    BOOL clickNavType = (navigationType == UIWebViewNavigationTypeLinkClicked);
    BOOL otherNavType = (navigationType == UIWebViewNavigationTypeOther);
    if (clickNavType || (otherNavType && ![webView isLoading])) {
      // First give the delegate a chance to handle the link
      if ([self reportDidClickLink:URL])
        shouldStart = NO;
      // If it's an internal page, jump to that page number.
      else if ([self moveToPageURL:URL animated:YES])
        shouldStart = NO;
      // Otherwise open the link internally or externally
      else {
        // Schemes that aren't supported by our browser always open externally
        if (linksOpenInExternalBrowser || ![KGBrowserViewController isSupportedScheme:scheme])
          [[UIApplication sharedApplication] openURL:URL];
        else {
          UIViewController *parentvc = [self firstAvailableViewControllerForView:self];
          if ([parentvc modalViewController] == nil) {
            KGBrowserViewController *bvc = [[[KGBrowserViewController alloc] init] autorelease];
            [bvc setModalPresentationStyle:UIModalPresentationFullScreen];
            [bvc setBackgroundColor:[UIColor blackColor]];
            [bvc setScalesPageToFit:YES];
            [bvc loadURL:URL];
            [parentvc presentModalViewController:bvc animated:YES];
          }  
        }  
        shouldStart = NO;
      }
    } 
  }
  return shouldStart;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [self webView:webView didFinish:KGPDFinishedLoad];
  if (![self webViewHasJavascriptDelay:webView])
    [self webView:webView didFinish:KGPDFinishedJS];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  [self webView:webView didFinish:KGPDFinishedLoad];
  if (![self webViewHasJavascriptDelay:webView])
    [self webView:webView didFinish:KGPDFinishedJS];
}

//------------------------------------------------------------------------------
// MARK: UIGestureRecognizerDelegate messages

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

//------------------------------------------------------------------------------
// MARK: NSKeyValueObserving customization messages

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  if ([key isEqualToString:@"paneNumber"] || [key isEqualToString:@"pageNumber"])
    return NO;
  else
    return [super automaticallyNotifiesObserversForKey:key];
}    

//------------------------------------------------------------------------------
// MARK: Private messages

- (void)initControl {
  lastLayoutSize = self.bounds.size;
  
  [self createScrollView];

  self.paneManager = [[[KGSinglePanePartitioning alloc] init] autorelease];
  
  mainFinishedMask = KGPDFinishedEverything;
  backgroundFinishedMask = KGPDFinishedEverything;
  
  scale = 1.0;
  
  self.imageStore = [[[KGInMemoryImageStore alloc] init] autorelease];
  
  self.leftImageView = [self createImageView];
  self.rightImageView = [self createImageView];
  self.centreImageView = [self createImageView];
  self.leftBusyView = [self createBusyView];
  self.rightBusyView = [self createBusyView];
  self.centreBusyView = [self createBusyView];

  currentOrientation = [self orientationForSize:self.bounds.size];  
}

- (BOOL)interfaceOrientationMatchesOrientation:(KGOrientation)orientation {
  UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
  return (
    (UIInterfaceOrientationIsLandscape(interfaceOrientation) && orientation == KGLandscapeOrientation) ||
    (UIInterfaceOrientationIsPortrait(interfaceOrientation) && orientation == KGPortraitOrientation)
  );
}

- (void)updateFractionalPosition {
  NSUInteger panes = [self numberOfPanes];
  if (scrollView.contentSize.width == 0 || panes == 0) {
    self.fractionalPaneNumber = 0;
    self.fractionalPageNumber = 0;
  }  
  else {  
    self.fractionalPaneNumber = scrollView.contentOffset.x / scrollView.contentSize.width * panes;
    self.fractionalPageNumber = [paneManager fractionalPageFromPane:fractionalPaneNumber orientation:currentOrientation];
  }
}

- (CGRect)frameForPaneNumber:(NSUInteger)pane {
  CGSize size = self.bounds.size;
  return CGRectMake(pane*size.width, 0, size.width, size.height);
}

- (CGRect)frameForPageNumber:(NSUInteger)page {
  CGSize size = self.bounds.size;
  return [paneManager frameForPageNumber:page pageSize:size orientation:currentOrientation];
}

- (void)createScrollView {
  self.scrollView = [[[KGCappedScrollView alloc] initWithFrame:self.bounds] autorelease];
  scrollView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
  
  scrollView.delegate = self;
  scrollView.pagingEnabled = YES;
  scrollView.scrollEnabled = YES;
  scrollView.showsVerticalScrollIndicator = NO;
  scrollView.showsHorizontalScrollIndicator = NO;
  scrollView.bounces = NO;
  scrollView.delaysContentTouches = NO;
  scrollView.clipsToBounds = YES;
  scrollView.backgroundColor = [self backgroundColor];
  scrollView.opaque = [self isOpaque];
  
  scrollView.scrollsToTop = NO;
  
  [self addSubview:scrollView];
}

- (void)repositionAfterLayoutChange {
  id position = [self savePosition];
  currentOrientation = [self orientationForSize:lastLayoutSize];
  navigator.pageOrientation = currentOrientation;
  paneNumber = -1;

  leftImageView.tag = rightImageView.tag = centreImageView.tag = -1;

  BOOL isLoaded = (mainFinishedMask == KGPDFinishedEverything && mainWebView.tag != -1);
  if (isLoaded) [paneManager layoutWebView:mainWebView pageSize:lastLayoutSize orientation:currentOrientation];

  [self refreshContentSize];
  [self restorePosition:position];

  if (isLoaded) [self sendActionsForControlEvent:KGControlEventContentLayoutChanged from:self];
  
  [self stopSnapshotting];
  [self startSnapshotting];
  
  [self showMainWebView];
}

- (UIImageView*)createImageView {
  UIImageView *imageView = [[UIImageView alloc] init];
  imageView.tag = -1;
  [scrollView addSubview:imageView];
  return [imageView autorelease];
}

- (UIActivityIndicatorView*)createBusyView {
  UIActivityIndicatorView *busyView = [[UIActivityIndicatorView alloc] init];
  busyView.tag = -1;
  busyView.opaque = NO;
  busyView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
  if ([busyView respondsToSelector:@selector(setColor:)]) {
    // the default UIActivityIndicatorViewStyleWhiteLarge is invisible against
    // a white background on iOS5. Fortunately we can now set the color.
    // TODO: something a bit more flexible here - what if the web page background
    // is lightGrayColor? We'd be in the exact same position.
    [(id)busyView setColor:[UIColor lightGrayColor]];
  }
  [scrollView addSubview:busyView];
  return [busyView autorelease];
}

- (void)preloadImageViewsForJumpFromPane:(NSInteger)start toPane:(NSInteger)end {
  NSInteger leftPane, rightPane;
  if (start < end) {
    leftPane = end;
    rightPane = end-1;
    start = MAX(start, end-2);
  }
  else {
    rightPane = end;
    leftPane = end+1;
    start = MIN(start, end+2);
  }
  
  leftImageView.image = [paneManager snapshotForPaneNumber:leftPane orientation:currentOrientation withOptions:KGImageStoreFetch];
  leftImageView.tag = leftPane;
  rightImageView.image = [paneManager snapshotForPaneNumber:rightPane orientation:currentOrientation withOptions:KGImageStoreFetch];
  rightImageView.tag = rightPane;
  
  [self setScrollViewAnimating:YES];
  CGRect rect = [self frameForPaneNumber:start];
  [scrollView scrollRectToVisible:rect animated:NO];
}

- (void)resetImageViewsForPageNumber:(NSUInteger)page offset:(NSUInteger)offset orientation:(KGOrientation)orientation {
  NSUInteger pane = [paneManager paneForPageNumber:page orientation:orientation] + offset;
  if (leftImageView.tag == pane) leftImageView.tag = -1;
  if (rightImageView.tag == pane) rightImageView.tag = -1;
  if (centreImageView.tag == pane) centreImageView.tag = -1;
}

- (void)positionImageViewsCentredOnPane:(NSInteger)pane {
  UIImageView **imageViews[] = { &leftImageView, &centreImageView, &rightImageView };
  for (int i = 0; i < 3; i++) {
    NSInteger relpane = pane+i-1;
    UIImageView **imageView = imageViews[i];
    for (int j = 0; j < 3; j++) {
      UIImageView **imageView2 = imageViews[j];
      if (i != j && (*imageView2).tag == relpane) {
        UIImageView *tmpImageView = *imageView;
        *imageView = *imageView2;
        *imageView2 = tmpImageView;
        break;
      }
    }
  }
  [self positionImageView:centreImageView andBusyView:centreBusyView forPane:pane];
  [self positionImageView:leftImageView andBusyView:leftBusyView forPane:pane - 1];
  [self positionImageView:rightImageView andBusyView:rightBusyView forPane:pane + 1];
}

- (void)positionImageView:(UIImageView*)imageView andBusyView:(UIActivityIndicatorView*)busyView forPane:(NSInteger)pane {
  if (pane < 0 || pane >= [self numberOfPanes]) {
    imageView.hidden = YES;
    busyView.hidden = YES;
  }
  else {
    UIImage *paneImage;
    if (imageView.tag == pane || scrollViewAnimating)
      paneImage = imageView.image;
    else
      paneImage = [paneManager snapshotForPaneNumber:pane orientation:currentOrientation withOptions:KGImageStoreFetch];

    CGRect paneFrame = [self frameForPaneNumber:pane];  
    if (paneImage) {
      imageView.image = paneImage;
      imageView.frame = paneFrame;
      if (!scrollViewAnimating) imageView.tag = pane;
      imageView.hidden = NO;
      busyView.hidden = YES;
      [busyView stopAnimating];
    }    
    else {
      // image isn't available yet - show a placeholder
      CGPoint paneOrigin = paneFrame.origin;
      CGSize paneSize = paneFrame.size;
      CGSize busySize = CGSizeMake(40, 40);
      CGRect busyFrame = CGRectMake(
        paneOrigin.x + (paneSize.width-busySize.width)/2, 
        paneOrigin.y + (paneSize.height-busySize.height)/2, 
        busySize.width, busySize.height
      );
      busyView.frame = busyFrame;
      busyView.hidden = NO;
      [busyView startAnimating];
      imageView.hidden = YES;
    }
  }
}

- (UIWebView*)createWebViewWithSize:(CGSize)size {
  // make sure web view is off-screen to prevent any flicker.
  // 0x0 seems to force the webview to redraw; without it there can be flicker as the webview briefly
  // shows the previously loaded view.
  // width > 0 but set to the minimum dimension (width or height) desired makes reflow work on rotation but
  // causes the previous-webview-visible flicker problem.
  //
  // TODO: update this comment to reflect reality
  
  CGRect frame = CGRectMake(0, 9999, size.width/2, size.height/2);
  //  CGRect frame = CGRectMake(0, 9999, size.width, size.height);
  //  CGRect frame = CGRectMake(0, 9999, 1, 1);
  //  CGRect frame = CGRectMake(0, 9999, size.width, size.height+1);
  UIWebView *webView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
  
  webView.tag = -1;
  webView.autoresizesSubviews = YES;
  webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
  webView.delegate = self;
  webView.scrollEnabled = NO;
  if (scale != 1.0 && scale != 0.0) webView.transform = CGAffineTransformMakeScale(scale, scale);
  
  [scrollView addSubview:webView];
  return webView;
}

- (void)stopWebView:(UIWebView*)webView {
  [webView setDelegate:nil];
  [webView stopLoading];
  webView.tag = -1;
}

- (void)initWebView:(UIWebView*)webView withDataSourcePageNumber:(NSUInteger)page foreground:(BOOL)foreground {
  NSURL *url = [dataSource urlForPageNumber:page];
  KGControlEvents event1 = (foreground ? KGControlEventDataSourceWillLoadForeground : KGControlEventDataSourceWillLoadBackground);
  [self sendActionsForControlEvent:event1 from:url];
  
  NSString *html = [NSMutableString stringWithContentsOfURL:url usedEncoding:nil error:nil];
  KGControlEvents event2 = (foreground ? KGControlEventDataSourceDidLoadForeground : KGControlEventDataSourceDidLoadBackground);
  [self sendActionsForControlEvent:event2 from:html];
  [webView loadHTMLString:html baseURL:url];
}

- (void)webView:(UIWebView*)webView didFinish:(KGPagedDocFinishedMask)finished {
  if (webView == mainWebView) {
    if (mainFinishedMask == KGPDFinishedEverything) return;
    mainFinishedMask |= finished;
    if (mainFinishedMask == KGPDFinishedEverything) {
      [self webView:mainWebView didFinishPageNumber:mainPageNumber pageSize:mainSize foreground:YES];
    }
  }
  
  if (webView == backgroundWebView) {
    if (backgroundFinishedMask == KGPDFinishedEverything) return;
    backgroundFinishedMask |= finished;
    if (backgroundFinishedMask == KGPDFinishedEverything) {
      [self webView:backgroundWebView didFinishPageNumber:backgroundPageNumber pageSize:backgroundSize foreground:NO];
    }
  }
}

- (void)webView:(UIWebView*)webView didFinishPageNumber:(NSUInteger)page pageSize:(CGSize)size foreground:(BOOL)foreground {
  CGRect frame = [self frameForPageNumber:page];
  webView.frame = CGRectMake(9999, 9999, frame.size.width, frame.size.height);
  webView.tag = page;
  
  [self sendActionsForControlEvent:KGControlEventContentLoadFinished from:webView];
  
  KGOrientation orientation = [self orientationForSize:size];
  if ([self interfaceOrientationMatchesOrientation:orientation]) {
    id position = [self savePosition];
    if ([paneManager layoutWebView:webView pageSize:size orientation:orientation]) {
      [self refreshContentSize];
      [self restorePosition:position];
    }
  }  

  NSString *fragment = nil;
  if (foreground) {
    if (targetFragmentPage == page)
      fragment = [[targetFragment copy] autorelease];
    [self setTargetFragment:nil];
    [self setTargetFragmentPage:0];
    
    [self showMainWebView];
    [self setMainWebViewFragment:fragment];
    [self moveToPaneWithFragment:fragment];
  }
  
  [paneManager takeSnapshotsForWebView:webView pageSize:size orientation:orientation progressHandler:^(NSUInteger offset, BOOL snapTaken){
    if (snapTaken)
      [self resetImageViewsForPageNumber:page offset:offset orientation:orientation];
    if (!offset) {
      if (snapTaken)
        [navigator newImageForPageNumber:page orientation:orientation];
      else  
        [self startupUpdateProgress:NO];
    }  
  } completionHandler:^(UIWebView *webView){
    [self startupUpdateProgress:YES];
    if (webView == mainWebView) {
      [self scrollMainWebViewToFragment:fragment];
      [self callbackMainWebViewAfterSnapshot];
      [self sendActionsForControlEvent:KGControlEventContentSnapshotFinished from:webView];
    }  
    if (webView == backgroundWebView) {
      backgroundBusyLoading = NO;
      [self startSnapshottingAfterDelay:0];
    }
  }];
}

- (BOOL)webViewHasJavascriptDelay:(UIWebView*)webView {
  NSString *mustDelayTag = [self metaTag:@"delaySnapshotUntilReady" forWebView:webView];
  return (mustDelayTag && [mustDelayTag localizedCaseInsensitiveCompare:@"yes"] == NSOrderedSame);    
}

- (NSString*)metaTag:(NSString*)tagName forWebView:(UIWebView*)webView {
  NSString *getMetaTagJS = [NSString stringWithFormat:
  @"function getMetaTag() {"
  @"  var m = document.getElementsByTagName('meta');"
  @"  for(var i in m) { "
  @"    if(m[i].name == '%@') {"
  @"      return m[i].content;"
  @"    }"
  @"  }"
  @"  return '';"
  @"}"
  @"getMetaTag();",tagName];
  return [webView stringByEvaluatingJavaScriptFromString:getMetaTagJS];
}

- (void)loadMainWebView {
  // page already loaded don't reload
  if (mainWebView && mainWebView.tag == pageNumber) return;
  
  // Cancel any background loads since we want the main load to take priority
  [self stopSnapshottingAndRestartAfterDelay:1.0];
  
  [self stopWebView:mainWebView];
  [mainWebView removeFromSuperview];
  
  mainPageNumber = pageNumber;
  mainSize = self.bounds.size;
  
  self.mainWebView = [self createWebViewWithSize:mainSize];
  mainWebView.tag = -1;
  mainWebView.backgroundColor = [self backgroundColor];
  mainWebView.opaque = [self isOpaque];
  mainWebView.scrollEnabled = scrollEnabled;
  mainWebView.mediaPlaybackRequiresUserAction = mediaPlaybackRequiresUserAction;
  self.currentPageView = mainWebView;
  
  mainFinishedMask = KGPDFinishedNothing;
  
  if (numberOfPages == 0) {
    NSString *blank = 
      @"<html><head>"
      @"<style>body {width:60%;font-family:Helvetica;font-size:300%;padding:25% 20%;} .small {font-size:50%;margin-top:2em;}</style>"
      @"<body><center><p>This page intentionally left blank.</p></center>"
      @"<center><p class='small'>Your data source did not return any data.</p></center></body></html>";
    [mainWebView loadHTMLString:blank baseURL:nil];
  }
  else
    [self initWebView:mainWebView withDataSourcePageNumber:mainPageNumber foreground:YES];
}

- (void)showMainWebView {
  if (mainFinishedMask != KGPDFinishedEverything) return;
  mainWebView.frame = [self frameForPageNumber:pageNumber];
  // When scrolling is enabled, we need to make sure the scroll width of the
  // web view is no wider than its view width. If not, the web view's scroller
  // will intercept gestures that were intended for the containing scroll view.
  if (scrollEnabled) [mainWebView setScrollWidth:mainWebView.bounds.size.width];
  if (!CGPointEqualToPoint(refreshScrollPosition, CGPointZero)) {
    UIScrollView *webScrollView = [[mainWebView subviews] lastObject];
    [webScrollView setContentOffset:refreshScrollPosition animated:NO];
    refreshScrollPosition = CGPointZero;
  }
  centreImageView.hidden = YES;
  centreBusyView.hidden = YES;
}

- (void)callbackMainWebViewAfterSnapshot {
  NSString *callback = [self metaTag:@"callbackWhenSnapshotFinished" forWebView:mainWebView];
  if (callback && [callback length]) {
    callback = [NSString stringWithFormat:@"%@();",callback];
    [mainWebView stringByEvaluatingJavaScriptFromString:callback];
  }  
}

- (void)scrollMainWebViewToFragment:(NSString*)fragment {
  if (fragment && [self isScrollEnabled]) {
    NSString *scrollScript = [NSString stringWithFormat:@
      "var el = document.getElementById('%@');"
      "var rect = el.getBoundingClientRect();"
      "rect.top + document.body.scrollTop;",fragment];
    NSInteger top = [[self stringByEvaluatingScript:scrollScript] integerValue];
    top -= fragmentScrollOffset;
    UIScrollView *webScrollView = [[mainWebView subviews] lastObject];
    NSInteger maxtop = webScrollView.contentSize.height - webScrollView.bounds.size.height;
    CGPoint offset = CGPointMake(webScrollView.contentOffset.x, MAX(MIN(top,maxtop),0));
    [webScrollView setContentOffset:offset animated:fragmentNavigationAnimated];
  }
}

- (void)setMainWebViewFragment:(NSString*)fragment {
  // This adds the fragment to the web view's document.location so that
  // any javscript on the page will be able to determine what fragment
  // was used when navigating to the page.
  if (fragment) {
    NSString *historyScript = [NSString stringWithFormat:@
      "history.replaceState(null,null,document.location.href+'#%@');",fragment];  
    [self stringByEvaluatingScript:historyScript];
  }
}

- (void)moveToPaneWithFragment:(NSString*)fragment {
  if (fragment) {
    NSInteger pane = [paneManager paneFromFragment:fragment inWebView:mainWebView pageSize:mainSize orientation:currentOrientation];
    if (pane != -1 && pane != paneNumber) [self setPaneNumber:pane animated:NO];  
  }
}

- (void)startSnapshottingAfterDelay:(CGFloat)delay {
  // Check whether we have already started a background load so that we don't
  // get a whole bunch of these queued up.
  if (!backgroundBusyLoading) {
    backgroundBusyLoading = YES;
    [self performSelector:@selector(loadBackgroundWebViews) withObject:nil afterDelay:delay];
  }
}

- (void)stopSnapshottingAndRestartAfterDelay:(CGFloat)delay {
  if (backgroundBusyLoading) {
    [self stopSnapshotting]; 
    [self startSnapshottingAfterDelay:delay];
  }
}

- (void)loadBackgroundWebViews {
  // Don't load while the main view is loading since that has a tendency to
  // cause rendering problems which show up in the snapshot.
  BOOL delayLoading = mainFinishedMask != KGPDFinishedEverything;

  // Don't load when the foreground webpage tells you not to; this allows highly
  // interactive foreground views to display and animate smoothly.
  if (!delayLoading) {
    NSString *stopSnapshottingTag = [self metaTag:@"stopSnapshotting" forWebView:mainWebView];
    delayLoading = (stopSnapshottingTag && [stopSnapshottingTag localizedCaseInsensitiveCompare:@"yes"] == NSOrderedSame);
  }

  if (delayLoading) {
    backgroundBusyLoading = NO;
    [self startSnapshotting];
    return;
  }
  
  backgroundBusyLoading = [self loadBackgroundWebViewsWithOrientation:currentOrientation size:lastLayoutSize];
}

- (BOOL)loadBackgroundWebViewsWithOrientation:(KGOrientation)orientation size:(CGSize)size {
  // Only render orientations that match the current interface orientation
  // otherwise the rendering won't be completely correct and the snapshot
  // image won't match the final rendering.
  if ([self interfaceOrientationMatchesOrientation:orientation])
    for (NSInteger i = 0; i < numberOfPages; i++) {
      // load pages that are closest to the current page first
      if ([self loadBackgroundWebViewsForPageNumber:pageNumber+i withOrientation:orientation size:size]) return YES;
      if ([self loadBackgroundWebViewsForPageNumber:pageNumber-i withOrientation:orientation size:size]) return YES;
    }
  [self startupUpdateProgress:YES];
  return NO;
}

- (BOOL)loadBackgroundWebViewsForPageNumber:(NSInteger)page withOrientation:(KGOrientation)orientation size:(CGSize)size {
  if (page < 0 || page >= numberOfPages) return NO;
  
  // If we already have snapshots for this page, we can skip it.
  if ([paneManager hasSnapshotsForPageNumber:page orientation:orientation]) return NO;
    
  [self stopWebView:backgroundWebView];
  [backgroundWebView removeFromSuperview];
  
  backgroundPageNumber = page;
  backgroundSize = size;
  
  self.backgroundWebView = [self createWebViewWithSize:backgroundSize];
  backgroundWebView.tag = -1;
  backgroundWebView.mediaPlaybackRequiresUserAction = YES;
  
  backgroundFinishedMask = KGPDFinishedNothing;
  [self initWebView:backgroundWebView withDataSourcePageNumber:backgroundPageNumber foreground:NO];
  return YES;
}

- (void)updateNavigatorDataSource {
  [navigator setDataSource:nil];
  [navigator setNumberOfPages:0];
  if (dataSource && imageStore) {
    [navigator setDataSource:imageStore];
    [navigator setNumberOfPages:numberOfPages];
  }
}

- (void)navigatorPageChanged {
  [self setPageNumber:navigator.pageNumber animated:YES];
}

- (void)preloadImagesForCurrentPane {
  [self preloadImagesForPane:paneNumber];
}
    
- (void)preloadImagesForPane:(NSUInteger)pane {
  // For a slow image cache, if we request an image while the view is scrolling,
  // it can cause the interface to jerk. By calling this function when a scroll
  // operation has just finished, we can give the cache a chance to preload
  // images that are soon likely to be needed, without having a negative impact
  // on the scrolling.
  NSUInteger panes = [self numberOfPanes];
  NSRange range = NSMakeRange(0, panes);
  for (NSInteger i = 3; i >= 2; i--) {
    [self preloadImageForPane:pane+i inRange:range];
    [self preloadImageForPane:pane-i inRange:range];
  }
}

- (void)preloadImageForPane:(NSInteger)pane inRange:(NSRange)range {
  if (pane >= range.location && pane < range.location+range.length)
    [paneManager snapshotForPaneNumber:pane orientation:currentOrientation withOptions:KGImageStorePrefetch];
}

- (void)startupUpdateProgress:(BOOL)afterSnapshot {
  // This function is called twice for each page: once immediately after the
  // page has loaded (but before the snapshot has been taken), and a second
  // time after the snapshot has been taken for the page.
  //
  // In order that the final 100% state actually has a chance to be seen, we
  // count 100% as being 1 step shy of complete (i.e. the last page has been
  // loaded, but not yet snapshot). When the snapshot is eventually taken
  // the loading screen will close immediately.
  
  if (startupView) {
    NSUInteger gotPages = [self startupPagesInitialised];
    
    if (gotPages >= startupRequiredPages) {
      [startupView removeFromSuperview];
      self.startupView = nil;
    }
    else {
      CGFloat fractionalPages = (CGFloat)gotPages + (afterSnapshot ? 0 : 0.5);
      CGFloat maximumPages = (CGFloat)startupRequiredPages - 0.5;
      [startupView setProgress:(fractionalPages / maximumPages)];
    }  
  }
}

- (NSUInteger)startupPagesInitialised {
  NSUInteger gotPages = 0;
  for (NSUInteger i = 0; i < startupRequiredPages; i++)
    if ([paneManager hasSnapshotsForPageNumber:i orientation:currentOrientation])
      gotPages++;
  return gotPages;
}

- (UIView*)isSelfOrChildFirstResponder:(UIView*)rootView {
  if (rootView.isFirstResponder) return rootView;     

  for (UIView *subView in rootView.subviews) {
    UIView *firstResponder = [self isSelfOrChildFirstResponder:subView];
    if (firstResponder != nil) return firstResponder;
  }

  return nil;
}

- (UIViewController*)firstAvailableViewControllerForView:(UIView*)view {
  id nextResponder = [view nextResponder];
  if ([nextResponder isKindOfClass:[UIViewController class]])
    return nextResponder;
  else if ([nextResponder isKindOfClass:[UIView class]])
    return [self firstAvailableViewControllerForView:nextResponder];
  else
    return nil;
}

- (void)sendActionsForControlEvent:(KGControlEvents)event from:(id)sender {
  NSSet *targets = [self allTargets];
  for (id target in targets) {
    NSArray *actions = [self actionsForTarget:target forControlEvent:event];
    for (NSString *actionString in actions) {
      SEL action = NSSelectorFromString(actionString);
      [target performSelector:action withObject:sender withObject:nil];
    }
  }
}

//------------------------------------------------------------------------------
// MARK: Delegate forwarders

- (BOOL)reportDidClickLink:(NSURL*)URL {
  if ([delegate respondsToSelector:@selector(document:didClickLink:)])
    return [delegate document:(KGPagedDocControl*)self didClickLink:URL];
  return NO;  
}

- (void)reportDidExecuteCommand:(NSURL*)URL {
  if ([delegate respondsToSelector:@selector(document:didExecuteCommand:)])
    [delegate document:(KGPagedDocControl*)self didExecuteCommand:URL];
}

@end

