/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

func hashString (obj: AnyObject) -> String {
    return String(ObjectIdentifier(obj).uintValue)
}


class LegacyUserContentController
{
    var scriptHandlersMainFrame = [String:WKScriptMessageHandler]()
    var scriptHandlersSubFrames = [String:WKScriptMessageHandler]()

    var scripts:[WKUserScript] = []
    weak var webView: BraveWebView?

    func addScriptMessageHandler(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        scriptHandlersMainFrame[name] = scriptMessageHandler
    }

    func removeScriptMessageHandler(name name: String) {
        scriptHandlersMainFrame.removeValueForKey(name)
        scriptHandlersSubFrames.removeValueForKey(name)
    }

    func addUserScript(script:WKUserScript) {
        var mainFrameOnly = true
        if !script.forMainFrameOnly {
            print("Inject to subframes")
            // Only contextMenu injection to subframes for now,
            // whitelist this explicitly, don't just inject scripts willy-nilly into frames without
            // careful consideration. For instance, there are security implications with password management in frames
            mainFrameOnly = false
        }
        scripts.append(WKUserScript(source: script.source, injectionTime: script.injectionTime, forMainFrameOnly: mainFrameOnly))
    }

    init(_ webView: BraveWebView) {
        self.webView = webView
    }

    static var jsPageHasBlankTargets:String = {
        let path = NSBundle.mainBundle().pathForResource("BlankTargetDetector", ofType: "js")!
        let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        return source
    }()

    func injectIntoMain() {
        guard let webView = webView else { return }

        let result = webView.stringByEvaluatingJavaScriptFromString("window.hasOwnProperty('webkit') && webkit.hasOwnProperty('messageHandlers') && window.hasOwnProperty('__firefox__')")
        if result == "true" {
            // already injected into this context
            return
        }

        // use tap detection until this returns false/
        // on page start reset enableBlankTargetTapDetection, then set it off when page loaded
        if webView.stringByEvaluatingJavaScriptFromString(LegacyUserContentController.jsPageHasBlankTargets) != "true" {
            // no _blank
            webView.blankTargetLinkDetectionOn = false
        }

        let js = LegacyJSContext()
        js.windowOpenOverride(webView, context:nil)

        for (name, handler) in scriptHandlersMainFrame {
            if !name.lowercaseString.contains("reader") {
                js.installHandlerForWebView(webView, handlerName: name, handler:handler)
            }
        }

        for script in scripts {
            webView.stringByEvaluatingJavaScriptFromString(script.source)
        }
    }

    func injectFingerprintProtection() {
        guard let webView = webView,
              let handler = scriptHandlersMainFrame[FingerprintingProtection.scriptMessageHandlerName()!] else { return }

        let js = LegacyJSContext()
        js.installHandlerForWebView(webView, handlerName: FingerprintingProtection.scriptMessageHandlerName(), handler:handler)
        webView.stringByEvaluatingJavaScriptFromString(FingerprintingProtection.script)

        let frames = js.findNewFramesForWebView(webView, withFrameContexts: nil)
        for ctx in frames {
            js.installHandlerForContext(ctx, handlerName: FingerprintingProtection.scriptMessageHandlerName(), handler:handler, webView:webView)
            js.callOnContext(ctx, script: FingerprintingProtection.script)
        }
    }

    func injectIntoSubFrame() {
        let js = LegacyJSContext()
        let contexts = js.findNewFramesForWebView(webView, withFrameContexts: webView?.knownFrameContexts)

        for ctx in contexts {
            js.windowOpenOverride(webView, context:ctx)

            webView?.knownFrameContexts.insert(ctx.hash)

            for (name, handler) in scriptHandlersSubFrames {
                js.installHandlerForContext(ctx, handlerName: name, handler:handler, webView:webView)
            }
            for script in scripts {
                if !script.forMainFrameOnly {
                    js.callOnContext(ctx, script: script.source)
                }
            }
        }
    }

    static func injectJsIntoAllFrames(webView: BraveWebView, script: String) {
        webView.stringByEvaluatingJavaScriptFromString(script)
        let js = LegacyJSContext()
        let contexts = js.findNewFramesForWebView(webView, withFrameContexts: nil)
        for ctx in contexts {
            js.callOnContext(ctx, script: script)
        }
    }
    
    func injectJsIntoPage() {
        injectIntoMain()
        injectIntoSubFrame()
    }
}

class BraveWebViewConfiguration
{
    let userContentController: LegacyUserContentController
    init(webView: BraveWebView) {
        userContentController = LegacyUserContentController(webView)
    }
}
