import SwiftUI
import AppKit

struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    @Binding var insertSymbol: String?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.delegate = context.coordinator
        
        // Fit text view inside scroll view
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update text if it changed externally (e.g. cleared)
        if textView.string != text {
            textView.string = text
        }
        
        // Handle symbol insertion from the sidebar
        if let symbolToInsert = insertSymbol {
            DispatchQueue.main.async {
                let range = textView.selectedRange()
                if textView.shouldChangeText(in: range, replacementString: symbolToInsert) {
                    textView.textStorage?.replaceCharacters(in: range, with: symbolToInsert)
                    textView.didChangeText()
                    
                    // Advance cursor past the inserted symbol
                    let newCursorLocation = range.location + symbolToInsert.count
                    textView.setSelectedRange(NSRange(location: newCursorLocation, length: 0))
                    
                    // Sync state back
                    self.text = textView.string
                }
                // Reset the trigger
                self.insertSymbol = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        var textView: NSTextView?
        
        init(_ parent: MacEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard let replacement = replacementString else { return true }
            
            // Check if we are typing a space or character that might trigger autocorrect
            if replacement == " " {
                // Construct the pending string to run autocorrect
                let currentText = textView.string
                let nsCurrentText = currentText as NSString
                
                // Temp string with the space inserted
                let tempText = nsCurrentText.replacingCharacters(in: affectedCharRange, with: " ")
                let tempRange = NSRange(location: affectedCharRange.location + 1, length: 0)
                
                // Run autocorrect
                if let autocorrectResult = MathAutocorrect.processAutocorrect(text: tempText, range: tempRange) {
                    // Apply autocorrect replacement directly
                    // Note: The autocorrectResult is based on the text *with* space,
                    // so we replace characters in the text storage accordingly.
                    let totalLengthToReplace = affectedCharRange.length + 1 // Plus the space
                    let replaceRange = NSRange(location: affectedCharRange.location, length: totalLengthToReplace)
                    
                    // The autocorrectResult.newText is the full document. 
                    // Let's replace the localized chunk in the textStorage to preserve undo stack.
                    let localReplacement = autocorrectResult.newText as NSString
                    let startLoc = affectedCharRange.location
                    
                    // Find the length of the replacement symbol
                    // The autocorrect result starts replacing from some start location up to the cursor
                    let autocorrectStart = tempRange.location - (tempText.count - autocorrectResult.newText.count)
                    // Wait, let's look at MathAutocorrect's return value:
                    // It returns the entire replacedText and the new cursor range.
                    // To keep undo working nicely, we can replace the text storage string.
                    textView.textStorage?.beginEditing()
                    textView.textStorage?.replaceCharacters(in: NSRange(location: 0, length: currentText.count), with: autocorrectResult.newText)
                    textView.textStorage?.endEditing()
                    
                    textView.didChangeText()
                    textView.setSelectedRange(autocorrectResult.newRange)
                    
                    parent.text = textView.string
                    return false // Intercepted, do not insert the space normally
                }
            }
            
            return true
        }
    }
}
