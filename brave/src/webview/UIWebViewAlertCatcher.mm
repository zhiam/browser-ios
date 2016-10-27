#import <UIKit/UIKit.h>

/// If the webview is not foreground, don't show an alert, this could be used to spoof users
/// TODO: queued up and shown

class WebFrame;

@interface UIWebView (JavaScriptAlert)
- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame;
@end

@implementation UIWebView (JavaScriptAlert)
- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
    UIAlertView* d = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    if (sender.superview != nil) {
        [d show];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JavaScriptPopupBlockedHiddenWebView" object:nil];
    }
}

@end
