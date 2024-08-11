//
//  SingleElimination.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//SingleElimination

import SwiftUI
import RealmSwift

struct SingleEliminationView: View {
    var tournament: Tournament

    var body: some View {
        ScrollView(.horizontal) {
            VStack {
                Text(tournament.name)
                    .font(.title)
                    .padding()

                VStack {
                    if let bracket = createBracket(from: Array(tournament.players)) {
                        BracketColumnView(matches: bracket)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Not enough players to create bracket")
                    }
                }
                .padding()
            }
            .navigationBarTitle("Tournament Bracket", displayMode: .inline)
        }
    }

    // Vytvoření pavouka z hráčů
    func createBracket(from players: [Player]) -> [[(Player?, Player?)]]? {
        guard players.count > 1 else { return nil }

        var rounds: [[(Player?, Player?)]] = []
        var currentRound: [(Player?, Player?)] = players.chunked(into: 2).map { ($0.first, $0.last) }

        while currentRound.count > 1 {
            rounds.append(currentRound)
            currentRound = currentRound.chunked(into: 2).map { ($0.first?.0, $0.last?.1) }
        }

        rounds.append(currentRound)
        return rounds
    }
}

struct BracketColumnView: View {
    var matches: [[(Player?, Player?)]]

    var body: some View {
        HStack(alignment: .top, spacing: 80) { // Zvýšené rozestupy mezi koly
            ForEach(matches.indices, id: \.self) { roundIndex in
                VStack(spacing: 60) { // Zvýšené rozestupy mezi zápasy
                    ForEach(matches[roundIndex].indices, id: \.self) { matchIndex in
                        ZStack {
                            MatchViewv(player1: matches[roundIndex][matchIndex].0,
                                      player2: matches[roundIndex][matchIndex].1)
                                .frame(width: 120, height: 80) // Zvýšená šířka a výška zápasů

                            if roundIndex < matches.count - 1 {
                                Path { path in
                                    let midX = CGFloat(120)
                                    let currentY = CGFloat(80)
                                    let spacing = CGFloat(60)
                                    let nextY = CGFloat(matchIndex / 2 * Int(currentY + spacing) + Int(currentY / 2))

                                    // Čára z hráče 1 do středu
                                    path.move(to: CGPoint(x: midX, y: 0))
                                    path.addLine(to: CGPoint(x: midX + 50, y: 0))

                                    // Čára z hráče 2 do středu
                                    path.move(to: CGPoint(x: midX, y: currentY))
                                    path.addLine(to: CGPoint(x: midX + 50, y: currentY))

                                    // Svislá čára spojující
                                    path.move(to: CGPoint(x: midX + 50, y: 0))
                                    path.addLine(to: CGPoint(x: midX + 50, y: currentY))

                                    // Vodorovná čára k dalšímu zápasu
                                    path.move(to: CGPoint(x: midX + 50, y: currentY / 2))
                                    path.addLine(to: CGPoint(x: midX + 100, y: nextY))
                                }
                                .stroke(Color.green, lineWidth: 2)
                            }
                        }
                    }
                }
            }
        }
    }
}


struct MatchViewv: View {
    var player1: Player?
    var player2: Player?

    var body: some View {
        VStack {
            Text(player1?.name ?? "TBD")
            Text("vs")
            Text(player2?.name ?? "TBD")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 1)
        )
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        for index in stride(from: 0, to: count, by: size) {
            let chunk = Array(self[index..<Swift.min(index + size, count)])
            chunks.append(chunk)
        }
        return chunks
    }
}
