import SwiftUI

struct BedtimeDetailView: View {
    let times: [Date]

    var body: some View {
        List(times, id: \.self) { t in
            Text(timeString(t))
        }
        .navigationTitle("Bedtimes")
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short               // ← spaces on both sides of '='
        return f.string(from: d)
    }
}
