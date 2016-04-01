#import <UIKit/UIKit.h>
#import "Swizzling.h"
#import <libkern/OSAtomic.h>


@implementation UIScrollView(DetectWebViewRender)

+ (void)load
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        SwizzleInstanceMethods(self.class, @selector(setContentOffset:), @selector(swizzled_setContentOffset:));
    });
}

volatile int32_t shouldCheck = 0;

+ (void)listenForRender
{
    OSAtomicTestAndSet(0, &shouldCheck);
}

/* UIWebView page drawing is accompanied by calls to this. In order to detect a render (and to take action post-render) send a notification.
 */
- (void)swizzled_setContentOffset:(CGPoint)p
{
    [self swizzled_setContentOffset:p];

    if (OSAtomicOr32(0, (uint32_t*)&shouldCheck) == 0) {
        return;
    }

    // "_UIWebScrollView" and others with UIWeb in the name only
    if ([NSStringFromClass([self class]) rangeOfString:@"UIWeb"].location == NSNotFound) {
        return;
    }

    OSAtomicTestAndClear(0, &shouldCheck);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScrollViewDetectedWebViewRender" object:nil];
    });
}

@end