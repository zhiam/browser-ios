#import <UIKit/UIKit.h>

// Used by 1PW snackbar to bypass showing the share activity picker

@interface UIActivityViewController(Cancel)
+ (void)hackyDismissal;

+ (void)hackyHideSharePickerOn:(bool)on;
@end
