//
//  PlayerPosition.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 16/10/2025.
//

import Foundation

enum PlayerPosition: String, CaseIterable, Codable, Identifiable {
    case pointGuard = "PG"
    case forward = "Forward"
    case center = "Center"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pointGuard: return "PG"
        case .forward:    return "Forward"
        case .center:     return "Center"
        }
    }
}
