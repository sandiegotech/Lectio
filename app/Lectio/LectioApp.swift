import SwiftUI

@main
struct LectioApp: App {
    @StateObject private var library = Library()
    @StateObject private var dictionary = WordDictionary()
    @StateObject private var saved = SavedStore()
    @StateObject private var theme = AppTheme()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(library)
                .environmentObject(dictionary)
                .environmentObject(saved)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
