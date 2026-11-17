import SwiftUI

@main
struct LectioApp: App {
    @StateObject private var library = Library()
    @StateObject private var saved = SavedStore()
    @StateObject private var reading = ReadingState()
    @StateObject private var theme = AppTheme()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(library)
                .environmentObject(saved)
                .environmentObject(reading)
                .environmentObject(theme)
                .preferredColorScheme(theme.preferredColorScheme)
        }
        // Back in the foreground on a later day: books released today appear.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { library.refreshReleases() }
        }
    }
}
