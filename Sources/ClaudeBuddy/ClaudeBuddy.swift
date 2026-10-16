import AppKit
import SwiftUI

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    private var statusItem: NSStatusItem?
    private let monitor = ClaudeMonitor()
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupFloatingPanel()
        setupMenuBar()
    }
    
    private func setupFloatingPanel() {
        let width: CGFloat = 260
        let height: CGFloat = 140
        
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let xPos = screenFrame.maxX - width - 40
        let yPos = screenFrame.minY + 40
        
        let frame = NSRect(x: xPos, y: yPos, width: width, height: height)
        
        let floatingPanel = FloatingPanel(contentRect: frame)
        let contentView = PixelMascotView(monitor: monitor)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.autoresizingMask = [.width, .height]
        
        floatingPanel.contentView = hostingView
        floatingPanel.makeKeyAndOrderFront(nil)
        self.panel = floatingPanel
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "🐱 95%"
            button.imagePosition = .imageLeft
        }
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let button = self.statusItem?.button else { return }
                let weekly = self.monitor.info.weeklyPercent
                let state = self.monitor.info.mascotState
                let icon: String
                switch state {
                case .coding: icon = "💻"
                case .analyzing: icon = "🔍"
                case .thinking: icon = "💭"
                case .panicking: icon = "⚠️"
                case .idle: icon = "🐱"
                case .sleeping: icon = "💤"
                }
                button.title = "\(icon) \(weekly)%"
                self.updateMenu()
            }
        }
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        let statusTitle = "Estado: \(monitor.info.mascotState.rawValue)"
        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        let sessionItem = NSMenuItem(
            title: "Sesión (5h): \(monitor.info.sessionPercent)% (\(monitor.info.sessionResetText))",
            action: nil,
            keyEquivalent: ""
        )
        sessionItem.isEnabled = false
        menu.addItem(sessionItem)
        
        let weeklyItem = NSMenuItem(
            title: "Semanal (7d): \(monitor.info.weeklyPercent)% (\(monitor.info.weeklyResetText))",
            action: nil,
            keyEquivalent: ""
        )
        weeklyItem.isEnabled = false
        menu.addItem(weeklyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let isVisible = panel?.isVisible ?? false
        let toggleTitle = isVisible ? "Ocultar Mascota" : "Mostrar Mascota"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleWidget), keyEquivalent: "m")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let resetPosItem = NSMenuItem(title: "Reiniciar Posición", action: #selector(resetPosition), keyEquivalent: "r")
        resetPosItem.target = self
        menu.addItem(resetPosItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Salir de ClaudeBuddy", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleWidget() {
        guard let panel = panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
        updateMenu()
    }
    
    @objc private func resetPosition() {
        guard let panel = panel else { return }
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 260
        let height: CGFloat = 140
        let xPos = screenFrame.maxX - width - 40
        let yPos = screenFrame.minY + 40
        panel.setFrame(NSRect(x: xPos, y: yPos, width: width, height: height), display: true, animate: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
