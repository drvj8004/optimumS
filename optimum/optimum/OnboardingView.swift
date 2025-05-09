import SwiftUI

/// 2-second splash with a starry-sky photo, app name and tagline.
/// No buttons – dismisses itself via `Task.sleep`.
struct SplashView: View {
    @Binding var showSplash: Bool          // bound from optimumApp

    var body: some View {
        ZStack {
            // 🌌 realistic sky artwork – add "SplashBackground" (PNG/JPEG)
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("optimum")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your personal sleep dashboard")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .task {
            // wait 2 s then hide splash
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showSplash = false }
        }
    }
}
