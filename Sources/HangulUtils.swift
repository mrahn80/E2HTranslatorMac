import Foundation

public struct HangulUtils {
    
    // QWERTY to Jamo mapping
    static let q2h: [Character: Character] = [
        "q":"ㅂ", "w":"ㅈ", "e":"ㄷ", "r":"ㄱ", "t":"ㅅ", "y":"ㅛ", "u":"ㅕ", "i":"ㅑ", "o":"ㅐ", "p":"ㅔ",
        "a":"ㅁ", "s":"ㄴ", "d":"ㅇ", "f":"ㄹ", "g":"ㅎ", "h":"ㅗ", "j":"ㅓ", "k":"ㅏ", "l":"ㅣ",
        "z":"ㅋ", "x":"ㅌ", "c":"ㅊ", "v":"ㅍ", "b":"ㅠ", "n":"ㅜ", "m":"ㅡ",
        "Q":"ㅃ", "W":"ㅉ", "E":"ㄸ", "R":"ㄲ", "T":"ㅆ", "O":"ㅒ", "P":"ㅖ"
    ]
    
    static let cho = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    static let jung = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
    static let jong = Array(" ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ") // Space for empty jong
    
    static let doubleJong: [String: Character] = [
        "ㄱㅅ": "ㄳ", "ㄴㅈ": "ㄵ", "ㄴㅎ": "ㄶ", "ㄹㄱ": "ㄺ", "ㄹㅁ": "ㄻ",
        "ㄹㅂ": "ㄼ", "ㄹㅅ": "ㄽ", "ㄹㅌ": "ㄾ", "ㄹㅍ": "ㄿ", "ㄹㅎ": "ㅀ",
        "ㅂㅅ": "ㅄ"
    ]
    
    static let doubleJung: [String: Character] = [
        "ㅗㅏ": "ㅘ", "ㅗㅐ": "ㅙ", "ㅗㅣ": "ㅚ",
        "ㅜㅓ": "ㅝ", "ㅜㅔ": "ㅞ", "ㅜㅣ": "ㅟ",
        "ㅡㅣ": "ㅢ"
    ]
    
    private static func isCho(_ c: Character) -> Bool { cho.contains(c) }
    private static func isJung(_ c: Character) -> Bool { jung.contains(c) }
    private static func isJong(_ c: Character) -> Bool { jong.contains(c) && c != " " }
    
    public static func convertEnglishTypedToKorean(_ englishWord: String) -> String {
        var jamos = [Character]()
        for char in englishWord {
            if let mapped = q2h[char] {
                jamos.append(mapped)
            } else {
                jamos.append(char)
            }
        }
        
        return composeHangul(from: jamos)
    }
    
    private static func composeHangul(from jamos: [Character]) -> String {
        var result = ""
        var state = 0
        var c_cho: Character?
        var c_jung: Character?
        var c_jong: Character?
        var c_jong2: Character?
        
        func flush() {
            if let choC = c_cho {
                if let jungC = c_jung {
                    let choIdx = cho.firstIndex(of: choC)!
                    let jungIdx = jung.firstIndex(of: jungC)!
                    var jongIdx = 0
                    if let jongC = c_jong {
                        var finalJong = jongC
                        if let j2 = c_jong2, let composedJong = doubleJong["\(jongC)\(j2)"] {
                            finalJong = composedJong
                        }
                        jongIdx = jong.firstIndex(of: finalJong) ?? 0
                    }
                    let scalarValue = 0xAC00 + (choIdx * 21 * 28) + (jungIdx * 28) + jongIdx
                    if let scalar = UnicodeScalar(scalarValue) {
                        result.append(Character(scalar))
                    }
                } else {
                    result.append(choC)
                }
            } else if let jungC = c_jung {
                result.append(jungC)
            }
            
            c_cho = nil
            c_jung = nil
            c_jong = nil
            c_jong2 = nil
            state = 0
        }
        
        var i = 0
        while i < jamos.count {
            let c = jamos[i]
            let isVowel = isJung(c)
            let isConsonant = cho.contains(c) || jong.contains(c)
            
            if !isVowel && !isConsonant {
                flush()
                result.append(c)
                i += 1
                continue
            }
            
            switch state {
            case 0:
                if isConsonant {
                    c_cho = c
                    state = 1
                } else {
                    c_jung = c
                    flush() // vowels stand alone if typed first
                }
            case 1:
                if isVowel {
                    c_jung = c
                    state = 2
                } else {
                    flush()
                    c_cho = c
                    state = 1
                }
            case 2:
                // could be compound vowel or jong
                if isVowel {
                    if let jung1 = c_jung, let composedJung = doubleJung["\(jung1)\(c)"] {
                        c_jung = composedJung
                    } else {
                        flush()
                        c_jung = c
                        flush()
                    }
                } else {
                    // Check if it's a valid final consonant
                    if jong.contains(c) && c != " " && c != "ㄸ" && c != "ㅃ" && c != "ㅉ" {
                        c_jong = c
                        state = 3
                    } else {
                        flush()
                        c_cho = c
                        state = 1
                    }
                }
            case 3:
                if isVowel {
                    // Jong was actually Cho of the next syllable
                    let nextCho = c_jong!
                    c_jong = nil
                    flush()
                    c_cho = nextCho
                    c_jung = c
                    state = 2
                } else {
                    if let j1 = c_jong, let _ = doubleJong["\(j1)\(c)"] {
                        c_jong2 = c
                        state = 4
                    } else {
                        flush()
                        c_cho = c
                        state = 1
                    }
                }
            case 4:
                if isVowel {
                    // Jong2 was actually Cho of the next syllable
                    let nextCho = c_jong2!
                    c_jong2 = nil
                    flush()
                    c_cho = nextCho
                    c_jung = c
                    state = 2
                } else {
                    flush()
                    c_cho = c
                    state = 1
                }
            default: break
            }
            
            i += 1
        }
        
        flush()
        return result
    }
}
