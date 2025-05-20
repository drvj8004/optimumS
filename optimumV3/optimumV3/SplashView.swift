
import SwiftUI

struct SplashView: View {
    @Binding var show: Bool
    var body: some View {
        ZStack{
            Image("NightSky").resizable().scaledToFill().ignoresSafeArea()
            VStack(spacing:8){
                Text("optimum").font(.system(size:48,weight:.heavy))
                Text("Your personal sleep dashboard").font(.subheadline).opacity(0.8)
            }.foregroundColor(.white)
        }
        .task{
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation{ show=false }
        }
    }
}
