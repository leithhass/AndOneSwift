//
//  AnalyticsService.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 14/10/2025.
//

import Foundation

enum AnalyticsEvent: String {
    case courtAdd, playerAdd, gameCreate, gameJoin, gameLeave, gameFull, seedDone
}

enum AnalyticsService {
    static func log(_ event: AnalyticsEvent, meta: [String: String] = [:]) {
        #if DEBUG
        print("📊 \(event.rawValue)", meta)
        #endif
    }
}
