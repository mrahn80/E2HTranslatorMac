import Foundation

public actor TranslationService {
    
    public init() {}
    
    /// Converts English keyboard keystrokes to their intended Hangul (Korean) representation.
    /// Performs the conversion asynchronously.
    public func translateAsync(_ text: String) async -> String {
        if text.isEmpty {
            return ""
        }
        
        var result = ""
        var currentWord = ""
        var inBackticks = false
        
        for char in text {
            if char == "`" {
                if !currentWord.isEmpty {
                    result += HangulUtils.convertEnglishTypedToKorean(currentWord)
                    currentWord = ""
                }
                inBackticks.toggle()
                continue
            }
            if inBackticks {
                result.append(char)
                continue
            }
            if isEnglishAlphabet(char) {
                currentWord.append(char)
            } else {
                if !currentWord.isEmpty {
                    result += HangulUtils.convertEnglishTypedToKorean(currentWord)
                    currentWord = ""
                }
                result.append(char)
            }
        }
        
        if !currentWord.isEmpty {
            result += HangulUtils.convertEnglishTypedToKorean(currentWord)
        }
        
        return postProcessTranslation(result)
    }
    
    private func isEnglishAlphabet(_ c: Character) -> Bool {
        return c.isASCII && c.isLetter
    }
    
    private func postProcessTranslation(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = ""
        
        // This function would normally do compatibility jamo merging.
        // HangulUtils implementation already handles valid typing composition,
        // so we don't strictly need the manual isolated-jamo post-process.
        // We will just replicate the backtick escape rule as in Java.
        
        result = text.replacingOccurrences(of: "`", with: "\\`")
        return result
    }
}
