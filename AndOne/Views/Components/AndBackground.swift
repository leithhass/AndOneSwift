//
//  AndBackground.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 22/10/2025.
//

import SwiftUI

public enum AndBackgroundStyle: Equatable {
    case auto, brand, mint, blueGray
}

private struct AndBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let style: AndBackgroundStyle

    func body(content: Content) -> some View {
        content
            .background(gradient.ignoresSafeArea())
            .background(noiseOverlay) // grain discret (optionnel)
    }

    private var gradient: LinearGradient {
        let top: Color
        let mid: Color = .andSurface
        let bottom: Color = .andSurface

        switch (style, scheme) {
        case (.brand, .light):      top = .andOrange.opacity(0.18)
        case (.brand, .dark):       top = .andOrange.opacity(0.25)
        case (.mint, .light), (.auto, .light):  top = .andMint.opacity(0.22)
        case (.mint, .dark),  (.auto, .dark):   top = .andMint.opacity(0.30)
        case (.blueGray, .light):   top = .andBlueGray.opacity(0.18)
        case (.blueGray, .dark):    top = .andBlueGray.opacity(0.30)
        case (_, _):
            <#code#>
        }

        return LinearGradient(colors: [top, mid, bottom],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }

    private var noiseOverlay: some View {
        Rectangle()
            .fill(.clear)
            .background(
                RadialGradient(gradient: Gradient(colors: [.black.opacity(0.04), .clear]),
                               center: .topLeading,
                               startRadius: 20,
                               endRadius: 500)
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}

public extension View {
    /// Fond AndOne réutilisable
    func andBackground(_ style: AndBackgroundStyle = .auto) -> some View {
        modifier(AndBackground(style: style))
    }
}
/// Fond AndOne réutilisable
