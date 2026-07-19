import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var window: NSPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "√x" // Premium mathematical symbol indicator
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // Create the SwiftUI ContentView
        let contentView = ContentView()
        
        // Configure the floating NSPanel (utility window)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 850, height: 550),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "EquationCraft"
        panel.level = .floating // Float on top of Illustrator / Affinity Designer
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.center()
        
        // Assign the SwiftUI view as the content
        panel.contentView = NSHostingView(rootView: contentView)
        self.window = panel
        
        // Show the window and activate the app on launch
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func toggleWindow() {
        guard let window = window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in status bar when window is closed
    }
}
