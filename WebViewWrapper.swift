import SwiftUI
import WebKit

struct WebViewWrapper: NSViewRepresentable {
    @Binding var latex: String
    @Binding var svgContent: String
    var isDarkMode: Bool
    
    func makeNSView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        // Setup message handler for two-way communications
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "mathEngine")
        configuration.userContentController = contentController
        
        // Allow file access for local MathJax library
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Make background transparent to integrate into the SwiftUI app
        webView.setValue(false, forKey: "drawsBackground")
        
        // Load the local index.html
        if let resourceURL = Bundle.main.resourceURL {
            let htmlURL = resourceURL.appendingPathComponent("Resources/index.html")
            let readAccessURL = resourceURL.appendingPathComponent("Resources")
            webView.loadFileURL(htmlURL, allowingReadAccessTo: readAccessURL)
        }
        
        context.coordinator.webView = webView
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Trigger render when latex state or theme changes
        context.coordinator.render(latex: latex, isDarkMode: isDarkMode)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewWrapper
        var webView: WKWebView?
        var isReady = false
        var pendingLatex: String?
        var pendingDarkMode: Bool?
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        func render(latex: String, isDarkMode: Bool) {
            guard isReady, let webView = webView else {
                // Buffer the render request until WebView is ready
                pendingLatex = latex
                pendingDarkMode = isDarkMode
                return
            }
            
            // Escape LaTeX characters for safe JS injection
            let escapedLatex = escapeForJavascript(latex)
            let jsCommand = "renderMath('\(escapedLatex)', \(isDarkMode));"
            
            DispatchQueue.main.async {
                webView.evaluateJavaScript(jsCommand, completionHandler: nil)
            }
        }
        
        private func escapeForJavascript(_ text: String) -> String {
            return text
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")
        }
        
        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // WebView has loaded, wait for the MathJax ready handler signal
        }
        
        // MARK: - WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "mathEngine",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }
            
            switch type {
            case "ready":
                isReady = true
                consoleLog("MathJax engine is fully initialized in WebView")
                // Render any buffered requests
                if let latex = pendingLatex, let darkMode = pendingDarkMode {
                    render(latex: latex, isDarkMode: darkMode)
                    pendingLatex = nil
                    pendingDarkMode = nil
                }
            case "svg":
                if let content = body["content"] as? String {
                    DispatchQueue.main.async {
                        self.parent.svgContent = content
                    }
                }
            case "error":
                if let errorMsg = body["content"] as? String {
                    consoleLog("KaTeX/MathJax Compile Error: \(errorMsg)")
                }
            default:
                break
            }
        }
        
        private func consoleLog(_ msg: String) {
            #if DEBUG
            print("[WebViewBridge] \(msg)")
            #endif
        }
    }
}
