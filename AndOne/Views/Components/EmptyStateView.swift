//
//  EmptyStateView.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 14/10/2025.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "basketball")
                .font(.system(size: 36, weight: .semibold))
                .padding(.bottom, 4)
            Text(title).font(.title3).bold()
            Text(message).multilineTextAlignment(.center).foregroundStyle(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
