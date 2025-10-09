//
//  Item.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 9/10/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
