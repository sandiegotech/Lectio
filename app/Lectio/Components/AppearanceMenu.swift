import SwiftUI

// Appearance control: Automatic (follow the device — auto-darkens at night), Day, Night.
struct AppearanceMenu: View {
    @EnvironmentObject var theme: AppTheme
    let pal: Palette

    var body: some View {
        Menu {
            Picker("Appearance", selection: $theme.mode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon).tag(mode)
                }
            }
        } label: {
            Image(systemName: theme.mode.icon)
                .font(.system(size: 15))
                .foregroundColor(pal.inkSoft)
                .padding(8)
                .background(Circle().fill(pal.rail))
                .overlay(Circle().stroke(pal.rule))
        }
    }
}
