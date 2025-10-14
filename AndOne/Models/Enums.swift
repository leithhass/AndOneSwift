import Foundation

// Court / Game core
enum CourtKind: String, Codable, CaseIterable { case half = "Demi", full = "Complet" }
enum CourtRequirement: String, Codable { case any, halfOnly, fullOnly }

enum GameKind: String, Codable, CaseIterable {
    case oneVone = "1v1", twoVtwo = "2v2", threeVthree = "3v3", fourVfour = "4v4", fiveVfive = "5v5"
    var capacity: Int { switch self {
        case .oneVone: 2; case .twoVtwo: 4; case .threeVthree: 6; case .fourVfour: 8; case .fiveVfive: 10
    }}
    var requiredCourt: CourtRequirement {
        switch self {
        case .oneVone, .twoVtwo: .halfOnly
        case .threeVthree: .any
        case .fourVfour, .fiveVfive: .fullOnly
        }
    }
}

enum GameStatus: String, Codable { case open, full, inProgress, finished }

// NEW — Gouvernorats & caractéristiques
enum Governorate: String, Codable, CaseIterable {
    case ariana = "Ariana", beja = "Béja", benArous = "Ben Arous", bizerte = "Bizerte", gabes = "Gabès",
         gafsa = "Gafsa", jendouba = "Jendouba", kairouan = "Kairouan", kasserine = "Kasserine",
         kebili = "Kebili", kef = "Le Kef", mahdia = "Mahdia", manouba = "La Manouba",
         medenine = "Médenine", monastir = "Monastir", nabeul = "Nabeul", sfax = "Sfax",
         sidiBouzid = "Sidi Bouzid", siliana = "Siliana", sousse = "Sousse", tataouine = "Tataouine",
         tozeur = "Tozeur", tunis = "Tunis", zaghouan = "Zaghouan"
}

enum SurfaceType: String, Codable, CaseIterable { case asphalt = "Asphalte", concrete = "Béton", other = "Autre" }
enum GroundCondition: String, Codable, CaseIterable { case good = "Bon", medium = "Moyen", bad = "Mauvais" }
