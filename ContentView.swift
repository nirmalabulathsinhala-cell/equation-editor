import SwiftUI
import AppKit

struct ContentView: View {
    @State private var latexInput: String = "E = mc^2"
    @State private var svgContent: String = ""
    @State private var insertSymbolTrigger: String? = nil
    
    // Status notifications (toasts)
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkModeOverride: Bool = false
    
    // Determine active rendering color scheme
    var isDarkMode: Bool {
        return isDarkModeOverride || colorScheme == .dark
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar: Symbol Picker
            VStack(alignment: .leading, spacing: 0) {
                Text("Symbols")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SymbolCategorySection(title: "Greek Letters", symbols: GreekLetters, trigger: $insertSymbolTrigger)
                        SymbolCategorySection(title: "Operators & Calculus", symbols: OperatorsAndCalculus, trigger: $insertSymbolTrigger)
                        SymbolCategorySection(title: "Relations & Logic", symbols: RelationsAndLogic, trigger: $insertSymbolTrigger)
                        SymbolCategorySection(title: "Arrows & Direction", symbols: ArrowsAndDirection, trigger: $insertSymbolTrigger)
                        SymbolCategorySection(title: "Chemistry & Units", symbols: ChemistryAndUnits, trigger: $insertSymbolTrigger)
                        SymbolCategorySection(title: "Shorthands & Presets", symbols: MathPresets, trigger: $insertSymbolTrigger)
                    }
                    .padding(12)
                }
            }
            .frame(width: 250)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Right Main Panels: Editor, Preview, and Controls
            VStack(spacing: 0) {
                // Header Toolbar
                HStack {
                    Text("EquationCraft")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Dark Mode Toggle
                    Button(action: {
                        isDarkModeOverride.toggle()
                    }) {
                        Image(systemName: isDarkModeOverride ? "moon.fill" : "sun.max")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle editor theme override")
                    
                    // Clear button
                    Button(action: {
                        latexInput = ""
                    }) {
                        Text("Clear")
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Split Editor and Preview
                VSplitView {
                    // Editor Panel (Top)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Equation Input")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Autocorrect active (try: \\alpha + Space, (a+b)/c + Space)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        MacEditorView(text: $latexInput, insertSymbol: $insertSymbolTrigger)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                    .background(Color(NSColor.underPageBackgroundColor))
                    
                    // Live Math Preview Panel (Bottom)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Live Vector Preview")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Drag preview to export .svg")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Render KaTeX MathJax View
                        WebViewWrapper(latex: $latexInput, svgContent: $svgContent, isDarkMode: isDarkMode)
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            // Drag-and-drop to export as an SVG file
                            .onDrag {
                                if let fileURL = createTemporarySVGFile() {
                                    return NSItemProvider(contentsOf: fileURL) ?? NSItemProvider()
                                }
                                return NSItemProvider()
                            }
                    }
                    .background(Color(NSColor.underPageBackgroundColor))
                }
                
                Divider()
                
                // Bottom Action Bar
                HStack(spacing: 12) {
                    // Copy SVG (Vectors for Illustrator/Affinity)
                    ActionButton(title: "Copy SVG (Vector)", subtitle: "For Illustrator / Affinity", icon: "doc.on.doc.fill", color: .blue) {
                        copySVGToClipboard()
                    }
                    
                    // Copy PNG (For Word/Mail)
                    ActionButton(title: "Copy PNG (Retina)", subtitle: "For Slides / Word / Mail", icon: "photo.fill", color: .purple) {
                        copyPNGToClipboard()
                    }
                    
                    // Copy LaTeX
                    ActionButton(title: "Copy LaTeX", subtitle: "For LaTeX document source", icon: "text.alignleft", color: .secondary) {
                        copyLaTeXToClipboard()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .overlay(
            // Premium Toast Notification
            VStack {
                if showToast {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 80)
                }
            }
        )
        .frame(minWidth: 850, minHeight: 550)
    }
    
    // MARK: - Clipboard Helpers
    
    private func copySVGToClipboard() {
        guard !svgContent.isEmpty else {
            triggerToast("No rendered equation to copy")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let svgType = NSPasteboard.PasteboardType("public.svg-image")
        let svgTypeXml = NSPasteboard.PasteboardType("image/svg+xml")
        
        pasteboard.declareTypes([svgType, svgTypeXml, .string], owner: nil)
        pasteboard.setString(svgContent, forType: svgType)
        pasteboard.setString(svgContent, forType: svgTypeXml)
        pasteboard.setString(svgContent, forType: .string)
        
        triggerToast("Vector SVG copied! Paste into Illustrator/Affinity.")
    }
    
    private func copyPNGToClipboard() {
        // We find the active WKWebView in our application windows and take a snapshot
        guard let window = NSApp.windows.first(where: { $0.title == "EquationCraft" }),
              let mainView = window.contentView else {
            triggerToast("Could not locate window to capture PNG")
            return
        }
        
        // Find WKWebView recursively
        guard let webView = findWebView(in: mainView) else {
            triggerToast("Rendering preview not ready")
            return
        }
        
        let snapshotConfig = WKSnapshotConfiguration()
        webView.takeSnapshot(with: snapshotConfig) { image, error in
            if let image = image {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
                self.triggerToast("Retina PNG image copied!")
            } else {
                self.triggerToast("PNG copy failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    private func copyLaTeXToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(latexInput, forType: .string)
        triggerToast("LaTeX markup copied!")
    }
    
    // Helper to write SVG to temporary file for drag-and-drop
    private func createTemporarySVGFile() -> URL? {
        guard !svgContent.isEmpty else { return nil }
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("equation.svg")
        do {
            try svgContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing temp SVG file: \(error)")
            return nil
        }
    }
    
    // Find WebView in view hierarchy
    private func findWebView(in view: NSView) -> WKWebView? {
        if let webView = view as? WKWebView {
            return webView
        }
        for subview in view.subviews {
            if let found = findWebView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Subcomponents

struct ActionButton: View {
    var title: String
    var subtitle: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SymbolCategorySection: View {
    var title: String
    var symbols: [SymbolItem]
    @Binding var trigger: String?
    
    @State private var isExpanded = true
    
    let columns = [
        GridItem(.adaptive(minimum: 40))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation { isExpanded.toggle() }
            }) {
                HStack {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(symbols, id: \.id) { item in
                        Button(action: {
                            trigger = item.code
                        }) {
                            VStack {
                                Text(item.display)
                                    .font(.system(size: 16))
                                    .frame(height: 28)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(4)
                            }
                            .help(item.code)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Symbol Data Structures

struct SymbolItem: Identifiable {
    let id = UUID()
    let display: String
    let code: String
}

// Sidebar symbols
let GreekLetters = [
    SymbolItem(display: "α", code: "\\alpha"),
    SymbolItem(display: "β", code: "\\beta"),
    SymbolItem(display: "γ", code: "\\gamma"),
    SymbolItem(display: "δ", code: "\\delta"),
    SymbolItem(display: "ε", code: "\\epsilon"),
    SymbolItem(display: "θ", code: "\\theta"),
    SymbolItem(display: "λ", code: "\\lambda"),
    SymbolItem(display: "μ", code: "\\mu"),
    SymbolItem(display: "π", code: "\\pi"),
    SymbolItem(display: "σ", code: "\\sigma"),
    SymbolItem(display: "ω", code: "\\omega"),
    SymbolItem(display: "Δ", code: "\\Delta"),
    SymbolItem(display: "Γ", code: "\\Gamma"),
    SymbolItem(display: "Θ", code: "\\Theta"),
    SymbolItem(display: "Λ", code: "\\Lambda"),
    SymbolItem(display: "Ω", code: "\\Omega")
]

let OperatorsAndCalculus = [
    SymbolItem(display: "×", code: "\\times"),
    SymbolItem(display: "÷", code: "\\div"),
    SymbolItem(display: "·", code: "\\cdot"),
    SymbolItem(display: "±", code: "\\pm"),
    SymbolItem(display: "√", code: "\\sqrt{x}"),
    SymbolItem(display: "∫", code: "\\int"),
    SymbolItem(display: "∑", code: "\\sum"),
    SymbolItem(display: "∏", code: "\\prod"),
    SymbolItem(display: "∂", code: "\\partial"),
    SymbolItem(display: "∇", code: "\\nabla"),
    SymbolItem(display: "lim", code: "\\lim_{x \\to \\infty}"),
    SymbolItem(display: "∞", code: "\\infty")
]

let RelationsAndLogic = [
    SymbolItem(display: "=", code: "="),
    SymbolItem(display: "≠", code: "\\ne"),
    SymbolItem(display: "≈", code: "\\approx"),
    SymbolItem(display: "≤", code: "\\le"),
    SymbolItem(display: "≥", code: "\\ge"),
    SymbolItem(display: "∝", code: "\\propto"),
    SymbolItem(display: "∈", code: "\\in"),
    SymbolItem(display: "∉", code: "\\notin"),
    SymbolItem(display: "⊂", code: "\\subset"),
    SymbolItem(display: "∪", code: "\\cup"),
    SymbolItem(display: "∩", code: "\\cap"),
    SymbolItem(display: "∴", code: "\\therefore")
]

let ArrowsAndDirection = [
    SymbolItem(display: "→", code: "\\rightarrow"),
    SymbolItem(display: "←", code: "\\leftarrow"),
    SymbolItem(display: "↑", code: "\\uparrow"),
    SymbolItem(display: "↓", code: "\\downarrow"),
    SymbolItem(display: "↔", code: "\\leftrightarrow"),
    SymbolItem(display: "⇒", code: "\\Rightarrow"),
    SymbolItem(display: "⇌", code: "\\rightleftharpoons")
]

let ChemistryAndUnits = [
    SymbolItem(display: "°", code: "^\\circ"),
    SymbolItem(display: "°C", code: "^\\circ\\text{C}"),
    SymbolItem(display: "aq", code: "\\text{ (aq)}"),
    SymbolItem(display: "g", code: "\\text{ (g)}"),
    SymbolItem(display: "s", code: "\\text{ (s)}"),
    SymbolItem(display: "l", code: "\\text{ (l)}"),
    SymbolItem(display: "mol", code: "\\text{mol}"),
    SymbolItem(display: "mL", code: "\\text{mL}")
]

let MathPresets = [
    SymbolItem(display: "a/b", code: "\\frac{a}{b}"),
    SymbolItem(display: "x²", code: "x^2"),
    SymbolItem(display: "x_i", code: "x_i"),
    SymbolItem(display: "Mat", code: "\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}")
]
