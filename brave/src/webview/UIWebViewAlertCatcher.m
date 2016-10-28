/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "Swizzling.h"

/// If the webview is not foreground, don't show an alert, this could be used to spoof users
/// TODO: queued up and shown

@implementation UIWebView (JavaScriptAlert)

+ (void)load
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        SwizzleInstanceMethods(self.class, @selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:), @selector(_webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:));
        SwizzleInstanceMethods(self.class, @selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:), @selector(_webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:));
        SwizzleInstanceMethods(self.class, @selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:), @selector(_webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:));
    });
}

-(BOOL)_webView:(id)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame
{
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
        return false;
    }

    return [self _webView:sender runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame];
}

- (void)_webView:(id)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame
{
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
        return;
    }

    [self _webView:sender runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame];
}

- (id)_webView:(id)arg1 runJavaScriptTextInputPanelWithPrompt:(id)arg2 defaultText:(id)arg3 initiatedByFrame:(id)arg4
{

    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
        return nil;
    }

    return [self _webView:arg1 runJavaScriptTextInputPanelWithPrompt:arg2 defaultText:arg3 initiatedByFrame:arg4];
}

@end
