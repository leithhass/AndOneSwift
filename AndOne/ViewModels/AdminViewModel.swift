import Foundation
import SwiftData

@MainActor
final class AdminViewModel: ObservableObject {

    func addCourt(
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
        condition: GroundCondition = .good,
        context: ModelContext
    ) {
        let c = Court(
            name: name,
            governorate: governorate,
            city: city,
            kind: kind,
            hoops: hoops,
            hasLighting: hasLighting,
            hasLockerRoom: hasLockerRoom,
            hasStands: hasStands,
            hasWaterPoint: hasWaterPoint,
            hasParking: hasParking,
            isAccessiblePMR: isAccessiblePMR,
            surface: surface,
            condition: condition
        )
        context.insert(c)
        try? context.save()
    }

    func addPlayer(nickname: String, level: Int, context: ModelContext) {
        let p = Player(nickname: nickname, level: level)
        context.insert(p)
        try? context.save()
    }
}
