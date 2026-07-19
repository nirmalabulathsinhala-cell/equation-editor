import Foundation

struct MathAutocorrect {
    // Dictionary mapping Word-style math autocorrect backslash codes to Unicode symbols
    static let symbolMappings: [String: String] = [
        // Lowercase Greek
        "\\alpha": "α",
        "\\beta": "β",
        "\\gamma": "γ",
        "\\delta": "δ",
        "\\epsilon": "ε",
        "\\zeta": "ζ",
        "\\eta": "η",
        "\\theta": "θ",
        "\\iota": "ι",
        "\\kappa": "κ",
        "\\lambda": "λ",
        "\\mu": "μ",
        "\\nu": "ν",
        "\\xi": "ξ",
        "\\pi": "π",
        "\\rho": "ρ",
        "\\sigma": "σ",
        "\\tau": "τ",
        "\\upsilon": "υ",
        "\\phi": "φ",
        "\\chi": "χ",
        "\\psi": "ψ",
        "\\omega": "ω",
        
        // Uppercase Greek
        "\\Delta": "Δ",
        "\\Gamma": "Γ",
        "\\Theta": "Θ",
        "\\Lambda": "Λ",
        "\\Xi": "Ξ",
        "\\Pi": "Π",
        "\\Sigma": "Σ",
        "\\Upsilon": "Υ",
        "\\Phi": "Φ",
        "\\Psi": "Ψ",
        "\\Omega": "Ω",
        
        // Operations & Symbols
        "\\times": "×",
        "\\div": "÷",
        "\\cdot": "·",
        "\\pm": "±",
        "\\mp": "∓",
        "\\infty": "∞",
        "\\partial": "∂",
        "\\nabla": "∇",
        "\\propto": "∝",
        "\\deg": "°",
        "\\degree": "°",
        
        // Calculus & Sets
        "\\int": "∫",
        "\\sum": "∑",
        "\\prod": "∏",
        "\\sqrt": "√",
        "\\in": "∈",
        "\\notin": "∉",
        "\\subset": "⊂",
        "\\supset": "⊃",
        "\\cap": "∩",
        "\\cup": "∪",
        
        // Relations
        "\\le": "≤",
        "\\ge": "≥",
        "\\ne": "≠",
        "\\approx": "≈",
        "\\equiv": "≡",
        "\\cong": "≅",
        "\\sim": "~",
        
        // Arrows
        "\\rightarrow": "→",
        "\\to": "→",
        "\\leftarrow": "←",
        "\\uparrow": "↑",
        "\\downarrow": "↓",
        "\\leftrightarrow": "↔",
        "\\Rightarrow": "⇒",
        "\\Leftarrow": "⇐",
        "\\Leftrightarrow": "⇔",
        "\\rightleftharpoons": "⇌" // Chemical equilibrium
    ]
    
    /// Process the current text and cursor position to apply autocorrect replacements.
    /// Returns the new text and new cursor position if a replacement occurred.
    static func processAutocorrect(text: String, range: NSRange) -> (newText: String, newRange: NSRange)? {
        guard range.length == 0, range.location > 0 else { return nil }
        
        let nsText = text as NSString
        let lastChar = nsText.substring(with: NSRange(location: range.location - 1, length: 1))
        
        // We trigger autocorrect on Space (or Tab/Enter if desired, let's focus on Space)
        guard lastChar == " " else { return nil }
        
        let textBeforeCursor = nsText.substring(to: range.location - 1)
        
        // 1. Try Fraction Conversion: e.g., (a+b)/c + Space -> \frac{a+b}{c}
        if let fractionResult = tryConvertFraction(textBeforeCursor) {
            let replacedText = nsText.replacingCharacters(in: NSRange(location: fractionResult.startLocation, length: range.location - fractionResult.startLocation), with: fractionResult.replacement)
            let newCursorPos = fractionResult.startLocation + fractionResult.replacement.count
            return (replacedText, NSRange(location: newCursorPos, length: 0))
        }
        
        // 2. Try Backslash Symbol Expansion: e.g., \alpha + Space -> α
        if let symbolResult = tryConvertSymbol(textBeforeCursor) {
            let replacedText = nsText.replacingCharacters(in: NSRange(location: symbolResult.startLocation, length: range.location - symbolResult.startLocation), with: symbolResult.replacement)
            let newCursorPos = symbolResult.startLocation + symbolResult.replacement.count
            return (replacedText, NSRange(location: newCursorPos, length: 0))
        }
        
        return nil
    }
    
    /// Checks if the text before cursor ends with a symbol shortcut like `\alpha`
    private static func tryConvertSymbol(_ textBeforeCursor: String) -> (startLocation: Int, replacement: String)? {
        // Look for the last backslash in the last word
        guard let backslashRange = textBeforeCursor.range(of: "\\", options: .backwards) else { return nil }
        
        let startIdx = backslashRange.lowerBound
        let shortcut = String(textBeforeCursor[startIdx...])
        
        // Check if it's a known symbol mapping
        if let unicodeReplacement = symbolMappings[shortcut] {
            let startLocation = textBeforeCursor.distance(from: textBeforeCursor.startIndex, to: startIdx)
            return (startLocation, unicodeReplacement)
        }
        
        return nil
    }
    
    /// Checks if the text before cursor forms a fraction expression like `(a+b)/c` or `x/y`
    private static func tryConvertFraction(_ textBeforeCursor: String) -> (startLocation: Int, replacement: String)? {
        guard !textBeforeCursor.isEmpty else { return nil }
        
        let chars = Array(textBeforeCursor)
        let len = chars.count
        
        // 1. Parse Denominator (scanning backwards from the end)
        var i = len - 1
        var denomEnd = i
        var denomStart = i
        
        if chars[i] == ")" {
            // Paren-enclosed denominator, find matching '('
            var parenCount = 1
            i -= 1
            while i >= 0 && parenCount > 0 {
                if chars[i] == ")" { parenCount += 1 }
                else if chars[i] == "(" { parenCount -= 1 }
                i -= 1
            }
            if parenCount > 0 { return nil } // Unbalanced parens
            denomStart = i + 2 // The '(' was at i+1
            denomEnd = len - 2 // Exclude the closing ')'
        } else {
            // Simple denominator (alphanumeric/word characters)
            while i >= 0 && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "." || chars[i] == "-" || chars[i] == "+") {
                i -= 1
            }
            denomStart = i + 1
            if denomStart == len { return nil } // No valid denominator characters
        }
        
        // 2. Check for the fraction bar '/'
        let slashIndex = denomStart - 1
        guard slashIndex >= 0 && chars[slashIndex] == "/" else { return nil }
        
        // 3. Parse Numerator (scanning backwards from slashIndex - 1)
        i = slashIndex - 1
        guard i >= 0 else { return nil }
        
        var numEnd = i
        var numStart = i
        
        if chars[i] == ")" {
            // Paren-enclosed numerator, find matching '('
            var parenCount = 1
            i -= 1
            while i >= 0 && parenCount > 0 {
                if chars[i] == ")" { parenCount += 1 }
                else if chars[i] == "(" { parenCount -= 1 }
                i -= 1
            }
            if parenCount > 0 { return nil } // Unbalanced
            numStart = i + 2
            numEnd = slashIndex - 2 // Exclude the closing ')'
        } else {
            // Simple numerator
            while i >= 0 && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "." || chars[i] == "-" || chars[i] == "+") {
                i -= 1
            }
            numStart = i + 1
            if numStart == slashIndex { return nil } // No valid numerator
        }
        
        // 4. Construct replacement LaTeX fraction string
        let numerator = String(chars[numStart...numEnd])
        let denominator = String(chars[denomStart...denomEnd])
        
        let latexFraction = "\\frac{\(numerator)}{\(denominator)}"
        
        // Start location of the replacement in the text (which is numStart - or numStart-1 if it was wrapped in a paren we want to replace)
        let actualStartPos = (numStart > 0 && chars[numStart-1] == "(" && numEnd < slashIndex-1 && chars[numEnd+1] == ")") ? numStart - 1 : numStart
        
        return (actualStartPos, latexFraction)
    }
}
