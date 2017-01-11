import UIKit
import WebKit

/*
 var http = new XMLHttpRequest();
 var url = "https://sync-staging.brave.com/abcdefg/credentials";
 var params = "";
 http.open("POST", url, true);
 http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
 http.onreadystatechange = function() {
     if(http.readyState == 4 && http.status == 200) {
         alert(http.responseText);
     }
 }
 http.send(params);
 */

class SyncWebView: UIViewController, WKScriptMessageHandler {
    var webView: WKWebView!

    var webConfig:WKWebViewConfiguration {
        get {
            let webCfg = WKWebViewConfiguration()
            let userController = WKUserContentController()

            ["fetch", "ios-sync", "bundle"].forEach() {
                userController.addUserScript(WKUserScript(source: getScript($0), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
            }

            webCfg.userContentController = userController
            return webCfg
        }
    }

    func getScript(name:String) -> String {
        let filePath = NSBundle.mainBundle().pathForResource(name, ofType:"js")
        return try! String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame = CGRectMake(20, 20, 100, 100)
        webView = WKWebView(frame: view.frame, configuration: webConfig)
        webView.navigationDelegate = self
        view.addSubview(webView)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //webView.loadHTMLString("<body>TEST<body>", baseURL: NSURL(string: "http://localhost:8000")!)
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://localhost:8000")!))
    }

    func webView(webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
    }
}

extension SyncWebView: WKNavigationDelegate {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {

    }
}

