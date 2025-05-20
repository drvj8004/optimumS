
import SwiftUI

struct BedtimeDetailView: View {
    let times:[Date]
    var body: some View {
        List(times,id:\ .self){ Text(DateUtils.timeString($0)) }
            .navigationTitle("Bedtimes")
    }
}
