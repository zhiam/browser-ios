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
        // Prefer not to swizzle these, but UIWebView has a sec hole that allows spoofing by showing JS popups, we need to plug that.
        NSString *alert = @"runJavaScriptAlertPanelWithMessage:initiatedByFrame:";
        NSString *confirm = @"runJavaScriptConfirmPanelWithMessage:initiatedByFrame:";
        NSString *textInput = @"runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:";

        SEL _alert = NSSelectorFromString([@"webView:" stringByAppendingString:alert]);
        SEL _confirm = NSSelectorFromString([@"webView:" stringByAppendingString:confirm]);
        SEL _textInput = NSSelectorFromString([@"webView:" stringByAppendingString:textInput]);

        SwizzleInstanceMethods(self.class, _alert, @selector(_webView:jsAlertPanelWithMessage:initiatedByFrame:));
        SwizzleInstanceMethods(self.class, _confirm, @selector(_webView:jsConfirmPanelWithMessage:initiatedByFrame:));
        SwizzleInstanceMethods(self.class, _textInput, @selector(_webView:jsTextInputPanelWithPrompt:defaultText:initiatedByFrame:));
    });
}

-(BOOL)_webView:(id)sender jsConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame
{
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
        return false;
    }

    return [self _webView:sender jsConfirmPanelWithMessage:message initiatedByFrame:frame];
}

- (void)_webView:(id)sender jsAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame
{
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
        return;
    }

    [self _webView:sender jsAlertPanelWithMessage:message initiatedByFrame:frame];
}

- (id)_webView:(id)arg1 jsTextInputPanelWithPrompt:(id)arg2 defaultText:(id)arg3 initiatedByFrame:(id)arg4
{
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
        return nil;
    }

    return [self _webView:arg1 jsTextInputPanelWithPrompt:arg2 defaultText:arg3 initiatedByFrame:arg4];
}

@end
