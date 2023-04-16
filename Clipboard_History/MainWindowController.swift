//
//  MainWindowController.swift
//  Clipboard_History
//
//  Created by 汪奕晖 on 2023/4/16.
//
import Cocoa
import SwiftUI

class MainWindowController: NSWindowController, NSWindowDelegate {
    convenience init(rootView: ContentView) {
        let windowSize = CGSize(width: 1000, height: 800)
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let originX = (screen.frame.width - windowSize.width) / 2
        let originY = (screen.frame.height - windowSize.height) / 2
        let newFrame = CGRect(origin: CGPoint(x: originX, y: originY), size: windowSize)
        
        let window = NSWindow(contentRect: newFrame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)

        self.init(window: window)
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}
