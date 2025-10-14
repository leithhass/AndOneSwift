import Foundation
import SwiftData

@Model
final class Game {
    @Attribute(.unique) var id: UUID
    var kind: GameKind
    var status: GameStatus
    var scheduledAt: Date
    var court: Court
    var players: [Player]
    var creatorId: UUID

    init(kind: GameKind, scheduledAt: Date, court: Court, players: [Player] = [], creatorId: UUID) {
        self.id = UUID(); self.kind = kind; self.status = .open
        self.scheduledAt = scheduledAt; self.court = court; self.players = players
        self.creatorId = creatorId; updateStatus()
    }
    var capacity: Int { kind.capacity }
    var spotsLeft: Int { max(0, capacity - players.count) }
    func isCourtCompatible() -> Bool {
        switch kind.requiredCourt { case .any: return true; case .halfOnly: return court.kind == .half; case .fullOnly: return court.kind == .full }
    }
    func updateStatus() { status = players.count >= capacity ? .full : .open }
}
