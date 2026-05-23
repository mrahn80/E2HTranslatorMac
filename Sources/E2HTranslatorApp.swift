import SwiftUI

@main
struct E2HTranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 850, minHeight: 550)
                .background(Color(red: 140/255, green: 142/255, blue: 154/255))
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
