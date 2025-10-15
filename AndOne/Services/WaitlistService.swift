//
//  WaitlistService.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 15/10/2025.
//

import Foundation

/// Stocke les matchs FULL à surveiller (clé locale robuste sans toucher au modèle)
enum WaitlistService {
    private static let key = "andone.waitlist_game_keys"

    /// clé = courtId + "_" + ISO minute de la date → évite les collisions
    static func keyFor(courtId: UUID, date: Date) -> String {
        let isoMinute = ISO8601DateFormatter()
        isoMinute.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withColonSeparatorInTimeZone, .withDashSeparatorInDate, .withTime, .withTimeZone, .withYear]
        let base = isoMinute.string(from: date)
        return "\(courtId.uuidString)_\(base.prefix(16))"
    }

    static func isWatching(_ k: String) -> Bool { keys().contains(k) }

    static func toggle(_ k: String) {
        var s = keys()
        if s.contains(k) { s.remove(k) } else { s.insert(k) }
        save(s)
    }

    static func keys() -> Set<String> {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            return Set(arr)
        }
        return []
    }

    private static func save(_ set: Set<String>) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }
}
