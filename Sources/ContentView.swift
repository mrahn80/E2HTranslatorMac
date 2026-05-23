import SwiftUI
import Combine

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var statusText: String = "Status: Ready"
    @State private var isConverting: Bool = false
    
    private let translationService = TranslationService()
    
    // Timer for debouncing (300ms)
    @State private var textChangedPublisher = PassthroughSubject<String, Never>()
    
    let inputPlaceholder = "Type QWERTY keystrokes here (e.g., 'rkskekfk')..."
    let outputPlaceholder = "Hangul output will appear instantly (e.g., '가나다라')..."
    
    var body: some View {
        VStack(spacing: 15) {
            // 1. Header Panel
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("E2H Keystroke Converter")
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Convert QWERTY Typos to Intended Hangul Instantly")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live Badge
                Text(isConverting ? "● INACTIVE" : "● ACTIVE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isConverting ? Color(red: 239/255, green: 68/255, blue: 68/255) : Color(red: 34/255, green: 197/255, blue: 94/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.bottom, 10)
            
            // 2. Text Areas
            GeometryReader { geometry in
                HStack(spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text(inputPlaceholder)
                                .foregroundColor(Color.gray.opacity(0.7))
                                .padding(16)
                                .padding(.top, 4)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $inputText)
                            .font(.system(size: 15))
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if outputText.isEmpty {
                            Text(outputPlaceholder)
                                .foregroundColor(Color.gray.opacity(0.7))
                                .padding(16)
                                .padding(.top, 4)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $outputText)
                            .font(.system(size: 15))
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            .disabled(true)
                    }
                }
            }
            
            // 3. Bottom Panel
            HStack {
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: clearAllFields) {
                    Text("🗑  Clear All")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: copyTranslation) {
                    Text("📋  Copy Converted Text")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 25/255, green: 118/255, blue: 210/255)) // Material Blue 700
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 245/255, green: 245/255, blue: 245/255)) // Material Grey 100
        .onReceive(
            textChangedPublisher
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        ) { text in
            performTranslation(text: text)
        }
        .onChange(of: inputText) { newValue in
            textChangedPublisher.send(newValue)
        }
    }
    
    private func performTranslation(text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            outputText = ""
            statusText = "Status: Ready"
            isConverting = false
            return
        }
        
        statusText = "Status: Converting..."
        isConverting = true
        
        Task {
            let translated = await translationService.translateAsync(text)
            
            await MainActor.run {
                outputText = translated
                statusText = "Status: Ready"
                isConverting = false
            }
        }
    }
    
    private func clearAllFields() {
        inputText = ""
        outputText = ""
        statusText = "Status: Ready"
    }
    
    private func copyTranslation() {
        guard !outputText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        
        statusText = "Status: Converted text copied to clipboard!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if statusText.starts(with: "Status: Converted text") {
                statusText = "Status: Ready"
            }
        }
    }
}
