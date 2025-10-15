import SwiftUI

/// Rangée d’icônes d’équipements (icône seule, couleur selon état)
struct CourtAmenityIcons: View {
    let court: Court
    let size: CGFloat = 16
    let spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            // Type de terrain (toujours affiché)
            Image(systemName: court.kind == .half ? "rectangle.leadinghalf.inset.filled" : "rectangle.inset.filled")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(Color.andInk)

            // Éclairage
            Image(systemName: "lightbulb")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(court.hasLighting ? Color.andOrange : Color.andInk)

            // Parking
            Image(systemName: "car.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(court.hasParking ? Color.andOrange : Color.andInk)

            // Eau
            Image(systemName: "drop.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(court.hasWaterPoint ? Color.andOrange : Color.andInk)

            // Vestiaires
            Image(systemName: "lock")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(court.hasLockerRoom ? Color.andOrange : Color.andInk)

            // Gradins
            Image(systemName: "person.3.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(court.hasStands ? Color.andOrange : Color.andInk)

            // PMR
            Image(systemName: "figure.roll")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(court.isAccessiblePMR ? Color.andOrange : Color.andInk)
        }
        .accessibilityLabel(Text("Équipements du terrain"))
    }
}
