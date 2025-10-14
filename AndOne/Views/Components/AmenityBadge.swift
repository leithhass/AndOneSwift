import SwiftUI

struct AmenityBadge: View {
    let systemName: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName).imageScale(.small)
            Text(label).font(.caption)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.andOrangeSoft.opacity(0.4), in: Capsule())
        .foregroundStyle(Color.andInk)
    }
}

struct CourtAmenityRow: View {
    let court: Court
    var maxBadges: Int = 3

    // Ordre: Type → Éclairage → Parking → Eau → autres
    private var badges: [(String,String)] {
        var arr: [(String,String)] = []
        if court.kind == .half { arr.append(("rectangle.leadinghalf.inset.filled", "Demi")) }
        if court.kind == .full { arr.append(("rectangle.inset.filled", "Complet")) }
        if court.hasLighting { arr.append(("lightbulb", "Éclairage")) }
        if court.hasParking { arr.append(("car.fill", "Parking")) }
        if court.hasWaterPoint { arr.append(("drop.fill", "Eau")) }
        if court.hasLockerRoom { arr.append(("lock", "Vestiaires")) }
        if court.hasStands { arr.append(("person.3.fill", "Gradins")) }
        if court.isAccessiblePMR { arr.append(("figure.roll", "PMR")) }
        return arr
    }

    var body: some View {
        let shown = Array(badges.prefix(maxBadges))
        let remaining = max(0, badges.count - shown.count)
        HStack(spacing: 8) {
            ForEach(0..<shown.count, id: \.self) { i in
                AmenityBadge(systemName: shown[i].0, label: shown[i].1)
            }
            if remaining > 0 {
                AmenityBadge(systemName: "ellipsis", label: "+\(remaining)")
            }
        }
    }
}
