import Foundation
import SwiftData

@Model
final class Player {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var level: Int
    init(nickname: String, level: Int = 3) {
        self.id = UUID(); self.nickname = nickname; self.level = max(1, min(5, level))
    }
}
