//
//  ContentView.swift
//  Clipboard_History
//
//  Created by 汪奕晖 on 2023/4/14.
//
import SwiftUI
import AppKit
import Combine

class ClipboardHistoryManager: ObservableObject {
    @AppStorage("clipboardHistory") private var clipboardHistoryData: Data = Data()
    @Published var clipboardHistory: [ClipboardItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(clipboardHistory) {
                clipboardHistoryData = encoded
            }
        }
    }

    init() {
        clipboardHistory = []
        loadClipboardHistory()
    }


    func toggleFolded(item: ClipboardItem) {
        if let index = clipboardHistory.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = clipboardHistory[index]
            updatedItem.folded.toggle()
            clipboardHistory[index] = updatedItem
        }
    }
    private func loadClipboardHistory() {
        if let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: clipboardHistoryData) {
            clipboardHistory = decoded
        }
    }

}




struct ClipboardItem: Codable, Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
    var folded: Bool
}

struct ContentView: View {
    @StateObject private var clipboardHistoryManager = ClipboardHistoryManager()
    
    private var groupedClipboardItems: [String: [ClipboardItem]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MMM.dd"
        
        var groupedItems: [String: [ClipboardItem]] = [:]
        
        for item in clipboardHistoryManager.clipboardHistory {
            let dateString = dateFormatter.string(from: item.timestamp)
            if groupedItems[dateString] == nil {
                groupedItems[dateString] = [item]
            } else {
                groupedItems[dateString]?.append(item)
            }
        }
        
        return groupedItems
    }

    
    
    var body: some View {
        VStack {
            Text("Clipboard History")
                .font(.custom("Avenir Next", size: 36))
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.top, 32)
            
            List {
                ForEach(groupedClipboardItems.keys.sorted(by: >), id: \.self) { dateString in
                    VStack(alignment: .center) {
                        HStack {
                            Spacer()
                            Text("----------\(dateString)----------")
                                .font(.system(.headline, design: .monospaced))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        ForEach(groupedClipboardItems[dateString]!, id: \.id) { item in
                            VStack(alignment: .leading) {
                                // Your existing Text views for content and timestamp
                            }
                            //.padding(.vertical, 4)
                        }
                    }
                }
                
                ForEach(clipboardHistoryManager.clipboardHistory) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.text)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .lineLimit(item.folded ? 2 : nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.white)
                            
                            Text(item.timestamp, style: .time)
                                .font(.system(size: 12, weight: .light, design: .rounded))
                                .foregroundColor(.gray)
                            
                            if item.text.count > 50 {
                                Button(action: {
                                    clipboardHistoryManager.toggleFolded(item: item)
                                }) {
                                    Text(item.folded ? "Show More" : "Show Less")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let index = clipboardHistoryManager.clipboardHistory.firstIndex(where: { $0.id == item.id }) {
                                clipboardHistoryManager.clipboardHistory.remove(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
            .ignoresSafeArea()
            .onAppear(perform: setup)
        }
    }
    func setup() {
        // TODO: Set up clipboard monitoring and update clipboardHistory
        let pasteboard = NSPasteboard.general
        var changeCount = pasteboard.changeCount

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if pasteboard.changeCount != changeCount {
                changeCount = pasteboard.changeCount
                
                if let copiedString = pasteboard.string(forType: .string) {
                    var updatedHistory = clipboardHistoryManager.clipboardHistory

                    let newItem = ClipboardItem(text: copiedString, timestamp: Date(), folded: true)
                    updatedHistory.insert(newItem, at: 0)
                    clipboardHistoryManager.clipboardHistory = updatedHistory

                }

                

                    

                }
            }
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
