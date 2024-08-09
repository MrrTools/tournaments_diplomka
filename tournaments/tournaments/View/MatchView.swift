//  MatchView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//

import SwiftUI

struct MatchView: View {
    var player1: Player?
    var player2: Player?

    var body: some View {
        VStack {
            Text(player1?.name ?? "TBD")
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            Text(player2?.name ?? "TBD")
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }
}
