//
//  UndoableTextView.swift
//  Clipboard_History
//
//  Created by 汪奕晖 on 2023/4/15.
//
import SwiftUI
import AppKit

struct UndoableTextView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.string = text
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: UndoableTextView

        init(_ textView: UndoableTextView) {
            self.parent = textView
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
