#import "SwizzlingToHideSharePicker.h"
#import <UIKit/UIKit.h>
#import "Swizzling.h"

bool hackyHide = false;

__weak UIAlertController *currentAlertView = nil;
__weak UIViewController *currentActivityView = nil;

@implementation UIAlertController(Hide)
+ (void)load
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        SwizzleInstanceMethods(self.class, @selector(viewWillAppear:), @selector(_viewWillAppear:));
    });
}

-(void)_viewWillAppear:(BOOL)animated
{
    if (hackyHide) {
        currentAlertView = self;
        self.view.alpha = 0.0;
    }
    [self _viewWillAppear:animated];
}

+ (void)hackyHideOn:(bool)on
{
    hackyHide = on;
    if (!on && currentAlertView) {
        currentAlertView.view.alpha = 1.0;
    }
}

@end


@implementation UIActivityViewController(Cancel)
+ (void)load
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        SwizzleInstanceMethods(self.class, @selector(viewWillAppear:), @selector(_viewWillAppear:));
    });
}

-(void)_viewWillAppear:(BOOL)animated
{
    [self _viewWillAppear:animated];
    currentActivityView = self;
}

+(void)hackyDismissal
{
    if (currentActivityView) {
        [currentActivityView dismissViewControllerAnimated:YES completion:nil];
    }
}

@end