#import "UIAlertController+Hide.h"
#import <UIKit/UIKit.h>
#import "Swizzling.h"


bool hackyHide = false;

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
        self.view.alpha = 0.0;
    }
    [self _viewWillAppear:animated];
}

+ (void)hackyHideOn:(bool)on
{
    hackyHide = on;
}

@end


