//
//  Clipboard_HistoryApp.swift
//  Clipboard_History
//
//  Created by 汪奕晖 on 2023/4/14.
//

import SwiftUI
import AppKit

class MenuManager: NSObject {
    @objc func showSettings(_ sender: NSMenuItem?) {
        let settingsWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        settingsWindow.center()
        settingsWindow.setFrameAutosaveName("Settings")
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.contentView = NSHostingView(rootView: SettingsView())
        settingsWindow.makeKeyAndOrderFront(nil)
    }
}



@main
struct Clipboard_HistoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
                    CommandGroup(after: .appInfo) {
                        Button(action: {
                            let menuManager = MenuManager()
                            menuManager.showSettings(nil)
                        }) {
                            Text("Settings")
                        }
                    }
                }
    }
}


