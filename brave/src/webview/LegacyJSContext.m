/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "LegacyJSContext.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "Client-Swift.h"

@interface FrameInfoWrapper : WKFrameInfo
@property (atomic, retain) NSURLRequest* writableRequest;
@end

@implementation FrameInfoWrapper

-(NSURLRequest*)request
{
  return self.writableRequest;
}

-(BOOL)isMainFrame
{
  return true;
}

@end

@interface LegacyScriptMessage: WKScriptMessage
@property (atomic, retain) NSObject* writeableBody;
@property (atomic, copy) NSString* writableName;
@property (atomic, retain) NSURLRequest* request;
@end
@implementation LegacyScriptMessage

-(id)body
{
  return self.writeableBody;
}

- (NSString*)name
{
  return self.writableName;
}

-(WKFrameInfo *)frameInfo
{
  static FrameInfoWrapper* f = 0;
  if (!f)
    f = [FrameInfoWrapper new];
  f.writableRequest = self.request;
  return f;
}

@end

@implementation LegacyJSContext

typedef void(^JSCallbackBlock)(NSDictionary*);

LegacyScriptMessage *message_ = 0;
WKUserContentController *userContentController_ = 0;

// Used to lookup the callback needed for a given handler name
NSMutableDictionary<NSString *, JSCallbackBlock> *callbackBlocks_ = 0;
NSMapTable<NSNumber *, UIWebView *> *handlerToWebview_ = 0;

// Handy method for getting unique values from object address to use as keys in a dict/hash
NSNumber* objToKey(id object) {
  return [NSNumber numberWithLongLong:(uintptr_t)object];
}

JSCallbackBlock blockFactory(NSString *handlerName, id<WKScriptMessageHandler> handler, UIWebView *webView)
{
  if (!handlerToWebview_) {
    handlerToWebview_ = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory];
  }

  [handlerToWebview_ setObject:webView forKey:objToKey(handler)];

  NSString *key = [NSString stringWithFormat:@"%@_%@_%@", handlerName, objToKey(handler), objToKey(webView)];

  if (!callbackBlocks_) {
    callbackBlocks_ = [NSMutableDictionary dictionary];
  }

  JSCallbackBlock result = [callbackBlocks_ objectForKey:key];
  if (result) {
    return result;
  }

  result =  ^(NSDictionary* message) {
      NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:message];

    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
      //NSLog(@"%@ %@", handlerName, message);
#endif
      if (!message_) {
        message_ = [LegacyScriptMessage new];
        userContentController_ = [WKUserContentController new];
      }

      message_.writeableBody = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
      message_.writableName = handlerName;
      if (handlerToWebview_) {
        UIWebView *webView = [handlerToWebview_ objectForKey:objToKey(handler)];
        if (webView) {
          message_.request = webView.request;
        }
      }

      [handler userContentController:userContentController_ didReceiveScriptMessage:message_];
    });
  };

  [callbackBlocks_ setObject:result forKey:key];

  return result;
}

- (void)installHandlerForContext:(id)_context
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
                         webView:(UIWebView *)webView
{

  JSContext* context = _context;
  NSString* script = [NSString stringWithFormat:@""
                      "if (!window.hasOwnProperty('webkit')) {"
                      "  Window.prototype.webkit = {};"
                      "  Window.prototype.webkit.messageHandlers = {};"
                      "}"
                      "if (!window.webkit.messageHandlers.hasOwnProperty('%@'))"
                      "  Window.prototype.webkit.messageHandlers.%@ = {};",
                      handlerName, handlerName];

  [context evaluateScript:script];

  context[@"Window"][@"prototype"][@"webkit"][@"messageHandlers"][handlerName][@"postMessage"] =
    blockFactory(handlerName, handler, webView);
}

- (void)installHandlerForWebView:(UIWebView *)webView
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
{
  assert([NSThread isMainThread]);
  JSContext* context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
  [self installHandlerForContext:context handlerName:handlerName handler:handler webView:webView];
}

- (void)windowOpenOverride:(UIWebView *)webView context:(id)_context
{
    assert([NSThread isMainThread]);
    JSContext *context = _context;
    if (!context) {
        context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    }

    if (!context) {
        return;
    }

    context[@"window"][@"open"] = ^(NSString *url) {
        [HandleJsWindowOpen open:url];
    };
}


- (void)callOnContext:(id)context script:(NSString*)script
{
  JSContext* ctx = context;
  [ctx evaluateScript:script];
}

- (NSArray *)findNewFramesForWebView:(UIWebView *)webView withFrameContexts:(NSSet*)contexts
{
  NSArray *frames = [webView valueForKeyPath:@"documentView.webView.mainFrame.childFrames"];
  NSMutableArray *result = [NSMutableArray array];

  [frames enumerateObjectsUsingBlock:^(id frame, NSUInteger idx, BOOL *stop ) {
    JSContext *context = [frame valueForKeyPath:@"javaScriptContext"];
    if (context && ![contexts containsObject:[NSNumber numberWithUnsignedInteger:context.hash]]) {
      [result addObject:context];
    }
  }];
  return result;
}

@end


NSString *js_ = @"function reportBlock(e){Window.prototype.hasOwnProperty('webkit')&&Window.prototype.webkit.hasOwnProperty('messageHandlers')&&Window.prototype.webkit.messageHandlers.hasOwnProperty('fingerprinting')&&webkit.messageHandlers.fingerprinting.postMessage(e)}function trapInstanceMethod(e){e.obj[e.propName]=function(o){return function(){var o={obj:e.objName,prop:e.propName};console.log('blocking canvas read',o),reportBlock(o)}}(e.obj[e.propName])}function trapIFrameMethods(e){var o=[{type:'Canvas',propName:'createElement',obj:e},{type:'Canvas',propName:'createElementNS',obj:e}];o.forEach(function(e){var o=e.obj[e.propName];e.obj[e.propName]=function(){var t=arguments,a=t[t.length-1];return a&&'canvas'===a.toLowerCase()?void reportBlock({obj:'document',propName:e.propName}):o.apply(this,t)}})}function inIFrame(){try{return window.self!==window.top}catch(e){return!0}}var methods=[],canvasMethods=['getImageData','getLineDash','measureText'];canvasMethods.forEach(function(e){var o={type:'Canvas',objName:'CanvasRenderingContext2D.prototype',propName:e,obj:window.CanvasRenderingContext2D.prototype};methods.push(o)});var canvasElementMethods=['toDataURL','toBlob'];canvasElementMethods.forEach(function(e){var o={type:'Canvas',objName:'HTMLCanvasElement.prototype',propName:e,obj:window.HTMLCanvasElement.prototype};methods.push(o)});var webglMethods=['getSupportedExtensions','getParameter','getContextAttributes','getShaderPrecisionFormat','getExtension'];webglMethods.forEach(function(e){var o={type:'WebGL',objName:'WebGLRenderingContext.prototype',propName:e,obj:window.WebGLRenderingContext.prototype};methods.push(o)});var audioBufferMethods=['copyFromChannel','getChannelData'];audioBufferMethods.forEach(function(e){var o={type:'AudioContext',objName:'AudioBuffer.prototype',propName:e,obj:window.AudioBuffer.prototype};methods.push(o)});var analyserMethods=['getFloatFrequencyData','getByteFrequencyData','getFloatTimeDomainData','getByteTimeDomainData'];analyserMethods.forEach(function(e){var o={type:'AudioContext',objName:'AnalyserNode.prototype',propName:e,obj:window.AnalyserNode.prototype};methods.push(o)}),methods.forEach(trapInstanceMethod),inIFrame()&&trapIFrameMethods(document);";

@protocol webframe<NSObject>
- (id)parentFrame;
@end

@interface OBS : NSObject
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
@end
@implementation OBS

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"here");
}

@end

OBS* obs = nil;

@implementation NSObject(JSContextSniffer)
- (void)webView:(id)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(id<webframe>)frame
{
    if (!obs) obs = [OBS new];

    if (![frame respondsToSelector: @selector(parentFrame)] || [frame parentFrame] == nil) {
        [webView addObserver:obs
                  forKeyPath:@"mainFrame.childFrames"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
        return;
    }

 //   [context evaluateScript:@"parent !== window && (document.createElement = {})"];
//    context[@"document"][@"createElement"] = ^(JSValue *tag) {
//        NSLog(@"BLOCKED %@", tag);
//    };
}

@end



#import "Swizzling.h"
@implementation NSMutableArray(SafeKit)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwizzleInstanceMethods(NSClassFromString(@"__NSArrayM"), @selector(addObject:), @selector(_addObject:));
    });
}


-(void)_addObject:(id)anObject
{
    if (!anObject) {
        return;
    }
    if ([NSStringFromClass([anObject class]) isEqualToString:@"WebFrame"]) {
        NSLog(@"-");
    }

    [self _addObject:anObject];
}



@end




