//
//  GameViewModel.swift
//  AndOne

import Foundation
import SwiftData

@MainActor
final class GameViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedKind: GameKind? = nil

    func create(kind: GameKind, date: Date, court: Court, creator: Player, context: ModelContext) throws {
        let game = Game(kind: kind, scheduledAt: date, court: court, players: [creator], creatorId: creator.id)
        guard game.isCourtCompatible() else { throw NSError(domain: "CourtIncompatible", code: 400) }
        context.insert(game)
        try context.save()
    }

    func join(_ game: Game, player: Player, context: ModelContext) throws {
        guard game.players.contains(where: { $0.id == player.id }) == false else { return }
        guard game.spotsLeft > 0 else { throw NSError(domain: "GameFull", code: 409) }
        game.players.append(player)
        game.updateStatus()
        try context.save()
    }

    func leave(_ game: Game, player: Player, context: ModelContext) throws {
        game.players.removeAll { $0.id == player.id }
        game.updateStatus()
        try context.save()
    }
}

