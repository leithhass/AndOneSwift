import Foundation
import SwiftData

@Model
final class Court {
    @Attribute(.unique) var id: UUID
    var name: String
    var governorate: Governorate
    var city: String
    var kind: CourtKind
    var hoops: Int

    // NEW — caractéristiques
    var hasLighting: Bool
    var hasLockerRoom: Bool
    var hasStands: Bool
    var hasWaterPoint: Bool
    var hasParking: Bool
    var isAccessiblePMR: Bool
    var surface: SurfaceType
    var condition: GroundCondition

    init(
        name: String,
        governorate: Governorate,
        city: String,
        kind: CourtKind,
        hoops: Int = 2,
        hasLighting: Bool = false,
        hasLockerRoom: Bool = false,
        hasStands: Bool = false,
        hasWaterPoint: Bool = true,
        hasParking: Bool = false,
        isAccessiblePMR: Bool = false,
        surface: SurfaceType = .asphalt,
        condition: GroundCondition = .good
    ) {
        self.id = UUID()
        self.name = name
        self.governorate = governorate
        self.city = city
        self.kind = kind
        self.hoops = hoops
        self.hasLighting = hasLighting
        self.hasLockerRoom = hasLockerRoom
        self.hasStands = hasStands
        self.hasWaterPoint = hasWaterPoint
        self.hasParking = hasParking
        self.isAccessiblePMR = isAccessiblePMR
        self.surface = surface
        self.condition = condition
    }
}
