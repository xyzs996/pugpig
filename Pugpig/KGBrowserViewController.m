//
//  KGBrowserViewController.m
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

#import "KGBrowserViewController+Internal.h"
#import "BackButton.png.h"
#import "ForwardButton.png.h"
#import "BrowserButton.png.h"

@interface UIViewController()
- (UIViewController*)presentingViewController;
@end

@implementation KGBrowserViewController

@synthesize title;
@synthesize toolbarHidden;
@synthesize backgroundColor;
@synthesize scalesPageToFit;
@synthesize canOpenExternalBrowser;
@synthesize linksOpenInExternalBrowser;
@synthesize webView;
@synthesize toolbar;
@synthesize navbar;
@synthesize backButton;
@synthesize forwardButton;
@synthesize browserButton;
@synthesize pendingHTMLContent;
@synthesize activeUrl;

static NSArray *KGStaticSupportedSchemes = nil;

+ (NSArray*)supportedSchemes {
  if (!KGStaticSupportedSchemes)
    KGStaticSupportedSchemes = [[NSArray alloc] initWithObjects:@"http",@"https",nil];
  return KGStaticSupportedSchemes;
}

+ (void)setSupportedSchemes:(NSArray*)schemes {
  if (KGStaticSupportedSchemes != schemes) {
    [KGStaticSupportedSchemes release];
    KGStaticSupportedSchemes = [schemes retain];
  }
}

+ (BOOL)isSupportedScheme:(NSString*)scheme {
  for (NSString *s in [self supportedSchemes])
    if ([s caseInsensitiveCompare:scheme] == NSOrderedSame)
      return YES;
  return NO;    
}

- (void)dealloc {
  webView.delegate = nil;
  [title release];
  [backgroundColor release];
  [webView release];
  [toolbar release];
  [navbar release];
  [backButton release];
  [forwardButton release];
  [browserButton release];
  [pendingHTMLContent release];
  [activeUrl release];
  [super dealloc];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  CGRect bounds = self.view.bounds;
  
  self.navbar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 44)] autorelease];
  navbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
  [navbar pushNavigationItem:self.navigationItem animated:NO];

  UIBarButtonItem *dismissItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAction:)] autorelease];
  self.navigationItem.title = title;
  self.navigationItem.rightBarButtonItem = dismissItem;
  
  self.toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, bounds.size.height - 44, bounds.size.width, 44)] autorelease];
  toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  toolbar.hidden = toolbarHidden;
  
  self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0 + 44, bounds.size.width, bounds.size.height - (toolbarHidden ? 44 : 88))] autorelease];
  webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  webView.scalesPageToFit = self.scalesPageToFit;
  webView.delegate = self;

  UIImage *backImage = [UIImage imageWithData:[NSData dataWithBytesNoCopy:BackButton_png length:BackButton_png_len freeWhenDone:NO]];
  self.backButton = [[[UIBarButtonItem alloc] initWithImage:backImage style:UIBarButtonItemStylePlain target:webView action:@selector(goBack)] autorelease];

  UIImage *forwardImage = [UIImage imageWithData:[NSData dataWithBytesNoCopy:ForwardButton_png length:ForwardButton_png_len freeWhenDone:NO]];
  self.forwardButton = [[[UIBarButtonItem alloc] initWithImage:forwardImage style:UIBarButtonItemStylePlain target:webView action:@selector(goForward)] autorelease];
  
  UIImage *browserImage = [UIImage imageWithData:[NSData dataWithBytesNoCopy:BrowserButton_png length:BrowserButton_png_len freeWhenDone:NO]];
  self.browserButton = [[[UIBarButtonItem alloc] initWithImage:browserImage style:UIBarButtonItemStylePlain target:self action:@selector(openInBrowserAction:)] autorelease];
  
  UIBarButtonItem	*spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
  
  toolbar.items = self.canOpenExternalBrowser ? [NSArray arrayWithObjects:backButton,forwardButton,spacer,browserButton,nil] : [NSArray arrayWithObjects:backButton,forwardButton,nil];
  
  [self enableNavButtons];

  [self.view addSubview:navbar];
  [self.view addSubview:toolbar];
  [self.view addSubview:webView];

  if (pendingHTMLContent)
    [webView loadHTMLString:pendingHTMLContent baseURL:nil];  
  else if (activeUrl)
    [webView loadRequest:[NSURLRequest requestWithURL:activeUrl]];

  if (backgroundColor) {
    self.view.backgroundColor = backgroundColor;
    toolbar.tintColor = backgroundColor;
    navbar.tintColor = backgroundColor;
  }
}

- (void)viewDidUnload {
  [super viewDidUnload];
  webView.delegate = nil;
  self.webView = nil;
  self.toolbar = nil;
  self.navbar = nil;
  self.backButton = nil;
  self.forwardButton = nil;
  self.browserButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)setTitle:(NSString*)newTitle {
  if (title != newTitle) {
    [title release];
    title = [newTitle copy];
    self.navigationItem.title = title;
  }
}

- (void)setBackgroundColor:(UIColor *)newBackgroundColor {
  if (backgroundColor != newBackgroundColor) {
    [backgroundColor release];
    backgroundColor = [newBackgroundColor retain];
    self.view.backgroundColor = backgroundColor;
    toolbar.tintColor = backgroundColor;
    navbar.tintColor = backgroundColor;
  }
}

- (void)setScalesPageToFit:(BOOL)newScalesPageToFit {
  if (scalesPageToFit != newScalesPageToFit) {
    scalesPageToFit = newScalesPageToFit;
    webView.scalesPageToFit = scalesPageToFit;
  }
}

- (void)setToolbarHidden:(BOOL)newToolbarHidden {
  if (toolbarHidden != newToolbarHidden) {
    toolbarHidden = newToolbarHidden;
    toolbar.hidden = toolbarHidden;
  }
}

- (void)loadHTMLString:(NSString*)html {
  self.pendingHTMLContent = html;
  if (webView) [webView loadHTMLString:html baseURL:nil];
}

- (void)loadURL:(NSURL*)url {
  self.activeUrl = url;
  if (webView) [webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)dismissAction:(id)sender {
  UIViewController *parent;
  // On iOS5 the parentViewController property isn't set anymore so you have to
  // use presentionViewController (which is specific to iOS5).
  if ([self respondsToSelector:@selector(presentingViewController)])
    parent = [(id)self presentingViewController];
  else
    parent = [self parentViewController];  
  [parent dismissModalViewControllerAnimated:YES];
}

- (void)openInBrowserAction:(id)sender {
  [[UIApplication sharedApplication] openURL:activeUrl];
}

- (void)enableNavButtons {
  [backButton setEnabled:[webView canGoBack]];
  [forwardButton setEnabled:[webView canGoForward]];
  [browserButton setEnabled:[KGBrowserViewController isSupportedScheme:activeUrl.scheme]];
}

//------------------------------------------------------------------------------
// MARK: UIWebViewDelegate messages

- (void)webViewDidFinishLoad:(UIWebView *)sender {
  if (!title) {
    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title;"];
  }
  self.activeUrl = webView.request.URL;
  [self enableNavButtons];
  webView.scalesPageToFit = self.scalesPageToFit;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)type {
  if (linksOpenInExternalBrowser && type == UIWebViewNavigationTypeLinkClicked) {
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
  }
  return YES;
}

@end
