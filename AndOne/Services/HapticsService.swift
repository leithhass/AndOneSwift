//
//  HapticsService.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 14/10/2025.
//

import UIKit

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
