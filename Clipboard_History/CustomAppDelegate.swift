//
//  CustomAppDelegate.swift
//  Clipboard_History
//
//  Created by 汪奕晖 on 2023/4/16.
//
import SwiftUI

class CustomAppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()

        windowController = MainWindowController(rootView: contentView)
        windowController.window?.center()
        windowController.window?.setFrameAutosaveName("Main Window")
        windowController.showWindow(nil)
    }
}



