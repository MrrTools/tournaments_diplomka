//
//  TournamentBackgroundView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 20.05.2026.
//

import SwiftUI

struct TournamentBackgroundView: View {
    let backgroundImageData: Data?
    let opacity: Double

    init(backgroundImageData: Data?, opacity: Double = 0.3) {
        self.backgroundImageData = backgroundImageData
        self.opacity = opacity
    }

    var body: some View {
        Group {
            if let backgroundImageData = backgroundImageData,
               let uiImage = UIImage(data: backgroundImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(opacity)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }
        }
    }
}
