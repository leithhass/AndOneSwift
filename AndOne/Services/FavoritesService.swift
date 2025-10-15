import Foundation

enum FavoritesService {
    private static let key = "andone.fav_court_ids"

    static func isFavorite(courtId: UUID) -> Bool {
        ids().contains(courtId)
    }

    static func toggle(courtId: UUID) {
        var s = ids()
        if s.contains(courtId) { s.remove(courtId) } else { s.insert(courtId) }
        save(s)
    }

    static func ids() -> Set<UUID> {
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([UUID].self, from: data) {
            return Set(arr)
        }
        return []
    }

    private static func save(_ set: Set<UUID>) {
        if let data = try? JSONEncoder().encode(Array(set)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
