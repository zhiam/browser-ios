#import <UIKit/UIKit.h>

// Used by 1PW snackbar to bypass showing the share activity picker

@interface UIAlertController(Hide)
+ (void)hackyHideOn:(bool)on;
@end

@interface UIActivityViewController(Cancel)
+ (void)hackyDismissal;
@end
