
Overview
--------

Pugpig is an open source framework that allows you to publish beautiful HTML5 magazines, books, newspapers and videos for the iPad, iPhone and more. Pugpig is a hybrid that mixes the best bits of native code with the juiciest cuts of HTML, producing a lovely reading experience whilst allowing you to publish once across all platforms.

How to use pugpig
-----------------

Read the [Getting Started Guide][2] on the pugpig website.

More information
----------------

For more information about the pugpig framework visit the [pugpig website][1].

Change log
----------

### Version 1.3 ###

  * Optimised performance on retina displays.
  * Smoother animation when jumping between pages that are far apart.
  * Improved snapshot image loading performance.
  * Allow highly interactive pages to pause the snapshotter while they're in the foreground. 
  * Attempt to retain the current scroll position when refreshing the current page.
  * Bugfix: we now only send the ContentLayoutChanged event after refreshing the content size and restoring the position.
  * Bugfix: jittery scrolling on scaled webview.

### Version 1.2 ###

  * Added property for setting the fragment scroll offset rather than hard coding it to the midpoint.
  * Only redraw the content in the thumbnail control if it's visible, which should improve performance when swiping between pages.
  * Bugfix: don't show internal browser view if another modal dialog is already visible.
  * Bugfix: fixed navigating to a fragment url on the current page.
  * Bugfix: plug memory leak in KGHTMLManifest.
  * Bugfix: if the pane manager was set, but the image store wasn't, then snapshots wouldn't work correctly.
  * Bugfix: navigator was being sent a newImageforPageNumber callback too often (i.e. when there wasn't actually a new image).
  * Bugfix: disable media autoplay for the snapshotter web view.

### Version 1.1 ###

* New features

  * Added an HTML manifest data source giving more control of page order.
  * Support for opening external links in a built in browser rather than opening Safari.
  * Support for moving to a particular page by specifing the page url.
  * Support for links to fragment urls.
  * Added methods for saving and restoring the current position.
  * Added the ability to specify a pane manager which can be extended to support multiple panes per page.
  * New properties for accessing the paneNumber, fractionalPaneNumber and numberOfPanes.
  * Additional control events for use when extending pugpig's base functionality.
  * Support for key-value observing on more properties for the same reason.
  * Support for intercepting links in the control delegate.
  * More control over the animation used when showing and hiding the navigator.
  * Support for a metatag that gets the app to callback javascript when snapshotting is complete
  * Changed the way our controls are allocated so they can be subclassed (to a limited extent).
  * Added a currentPageView property providing access to the UIWebView of the current page.
  * Added a method for evaluating scripts on the current page.
  * Support for specifying the cache directory when instantiating a disk image store.
  * Support for specifying an absolute path when instantiating a local file data source.
  * Several bug fixes and interface changes.

* Breaking changes

  * For reasons of efficiency, the page number is no longer set automatically when setting the datasource.
  * The portraitSize and landscapeSize properties have been removed.
  * The data source protocol has been renamed and the methods simplified.
  * The image store protocol has been renamed, many of the methods changed, and several new methods added.
  * The navigator protocol no longer has an active property and the dataSource and imageStore types have changed.

### Version 1.0 ###

  * Initial release

License
-------

Copyright (c) 2012, Kaldor Holdings Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of pugpig nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


  [1]: http://pugpig.com/
  [2]: http://pugpig.com/docs_getstarted

