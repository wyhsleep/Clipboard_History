//
//  ContentView.swift
//  Clipboard_History
//
//  Created by 汪奕晖 on 2023/4/14.
//
// Import necessary libraries
import SwiftUI
import AppKit
import Combine


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
// ClipboardHistoryManager: Manages and stores the clipboard history
class ClipboardHistoryManager: ObservableObject {
    // Store the clipboard history data
    @AppStorage("clipboardHistory") private var clipboardHistoryData: Data = Data()
    // Publish the clipboard history
    @Published var clipboardHistory: [ClipboardItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(clipboardHistory) {
                clipboardHistoryData = encoded
            }
        }
    }

    // Initialize the clipboard history
    init() {
        clipboardHistory = []
        loadClipboardHistory()
    }

    // Toggle folded state of a clipboard item
    func toggleFolded(item: ClipboardItem) {
        if let index = clipboardHistory.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = clipboardHistory[index]
            updatedItem.folded.toggle()
            clipboardHistory[index] = updatedItem
        }
    }
    
    // Load clipboard history from stored data
    private func loadClipboardHistory() {
        if let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: clipboardHistoryData) {
            clipboardHistory = decoded
        }
    }
}

struct CustomColors {
    let background: String
    let text: String
    let accent: String
    let secondaryText: String
    let highlight: String
}

let lightColors = CustomColors(
    background: "#F0F0F0",
    text: "#222222",
    accent: "#007BFF",
    secondaryText: "#666666",
    highlight: "#FFE082"
)

let darkColors = CustomColors(
    background: "#1E1E1E",
    text: "#E0E0E0",
    accent: "#0A84FF",
    secondaryText: "#A0A0A0",
    highlight: "#FFA500"
)



// ClipboardItem: Represents a single item in the clipboard history
struct ClipboardItem: Codable, Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
    var folded: Bool
}

struct SearchBar: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.delegate = context.coordinator
        return searchField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        let parent: SearchBar

        init(_ parent: SearchBar) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let searchField = obj.object as? NSSearchField {
                parent.text = searchField.stringValue
            }
        }
    }
}



// ContentView: Main view of the app
struct ContentView: View {
    @StateObject private var clipboardHistoryManager = ClipboardHistoryManager()
    @State private var searchText = ""
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var selectedItem: ClipboardItem? = nil
    @Environment(\.colorScheme) private var colorScheme

    private func filteredItems() -> [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardHistoryManager.clipboardHistory
        } else {
            return clipboardHistoryManager.clipboardHistory.filter { item in
                item.text.localizedStandardContains(searchText)
            }
        }
    }

    // Group clipboard items by date
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
    
    var colors: CustomColors {
        return colorScheme == .dark ? darkColors : lightColors
    }

    // Main body of the view
    var body: some View {
        VStack {
            // Title of the app
            Text("Clipboard History")
                .font(.custom("Avenir Next", size: 36))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: colors.accent))
                .padding(.top, 32)
            ScrollViewReader { proxy in
                // List to display the grouped clipboard items
                List {
                    
                    if let selectedItem = selectedItem {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(selectedItem.text)
                                    .font(.system(size: 16, weight: .regular, design:.rounded))
                                    .lineLimit(selectedItem.folded ? 2 : nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(Color(hex: colors.secondaryText))

                                // Display the timestamp of the clipboard item
                                Text(selectedItem.timestamp, style: .time)
                                    .font(.system(size: 12, weight: .light, design: .rounded))
                                    .foregroundColor(.gray)

                                // Show More/Show Less button for long text
                                if selectedItem.text.count > 50 {
                                    Button(action: {
                                        clipboardHistoryManager.toggleFolded(item: selectedItem)
                                    }) {
                                        Text(selectedItem.folded ? "Show More" : "Show Less")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
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
                    
                    // List the clipboard items individually
                    ForEach(filteredItems(), id: \.id) { item in
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(item.text)
                                                        .font(.system(size: 16, weight: .regular, design:.rounded))
                                                        .lineLimit(item.folded ? 2 : nil)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .foregroundColor(Color(hex: colors.text))

                                                    // Display the timestamp of the clipboard item
                                                    Text(item.timestamp, style: .time)
                                                        .font(.system(size: 12, weight: .light, design: .rounded))
                                                        .foregroundColor(.gray)

                                                    // Show More/Show Less button for long text
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
                                                .gesture(TapGesture().onEnded { _ in
                                                    selectedItem = item
                                                })

                                                Spacer()

                                                // Delete button for the clipboard item
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
                                            .buttonStyle(PlainButtonStyle())
                                            .padding()
                                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: colors.background)))
                                            .padding(.vertical, 4)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .onAppear {
                                        scrollViewProxy = proxy
                                    }
                                }

                                // Scroll to top button
                                ZStack(alignment: .bottom){
                                    VStack {
                                        HStack {
                                            SearchBar(text: $searchText)
                                                .padding(.leading)
                                                .frame(width: 250, alignment: .leading)
                                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                if let latestItemId = clipboardHistoryManager.clipboardHistory.first?.id {
                                                    scrollViewProxy?.scrollTo(latestItemId, anchor: .top)
                                                }
                                            }) {
                                                Image(systemName: "chevron.up.circle")
                                                    .resizable()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.blue)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding()
                                            .background(Color.white.opacity(0.0))
                                            .clipShape(Circle())
                                            .padding(.trailing)
                                        }
                                    }
                                }
                            }
                        }
    // Set up clipboard monitoring and update clipboard history
    func setup() {
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

// Preview for ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

