/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "AdBlockCppFilter.h"
#import <UIKit/UIKit.h>
#include "ABPFilterParser.h"

static ABPFilterParser parser;

@interface AdBlockCppFilter()
@property (nonatomic, retain) NSData *data;
@end

@implementation AdBlockCppFilter

-(void)setAdblockDataFile:(NSData *)data
{
    @synchronized(self) {
        self.data = data;
        parser.deserialize((char *)self.data.bytes);
    }
}

-(BOOL)hasAdblockDataFile
{
    @synchronized(self) {
        return self.data != nil;
    }
}

//extern int vm_pressure_monitor(int wait_for_pressure, int nsecs_monitored, uint32_t *pages_reclaimed);

+ (instancetype)singleton
{
    static AdBlockCppFilter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];

        //vm_pressure_monitor(1,1, 0);

        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MEMORYPRESSURE, 0, DISPATCH_MEMORYPRESSURE_NORMAL|DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL, dispatch_get_main_queue());
        dispatch_source_set_event_handler(source, ^{
            dispatch_source_memorypressure_flags_t pressureLevel = dispatch_source_get_data(source);
            [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil userInfo:@{@"pressure": @(pressureLevel)}];
        });
        dispatch_resume(source);

    });
    return instance;
}

- (BOOL)checkWithCppABPFilter:(NSString *)url
              mainDocumentUrl:(NSString *)mainDoc
             acceptHTTPHeader:(NSString *)acceptHeader
{
    if (![self hasAdblockDataFile]) {
        return false;
    }

    FilterOption option = FONoFilterOption;
    if (acceptHeader) {
        if ([acceptHeader rangeOfString:@"/css"].location != NSNotFound) {
            option  = FOStylesheet;
        }
        else if ([acceptHeader rangeOfString:@"image/"].location != NSNotFound) {
            option  = FOImage;
        }
        else if ([acceptHeader rangeOfString:@"javascript"].location != NSNotFound) {
            option  = FOScript;
        }
    }
    if (option == FONoFilterOption) {
        if ([url hasSuffix:@".js"]) {
            option = FOScript;
        }
        else if ([url hasSuffix:@".png"] || [url hasSuffix:@".jpg"] || [url hasSuffix:@".jpeg"] || [url hasSuffix:@".gif"]) {
            option = FOImage;
        }
        else if ([url hasSuffix:@".css"]) {
            option = FOStylesheet;
        }
    }

    return parser.matches(url.UTF8String, option, mainDoc.UTF8String);
}

@end
