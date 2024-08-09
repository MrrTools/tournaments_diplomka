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

                // Začátek pavouka
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
        HStack(alignment: .top, spacing: 50) {
            ForEach(matches.indices, id: \.self) { roundIndex in
                VStack(spacing: 40) {
                    ForEach(matches[roundIndex].indices, id: \.self) { matchIndex in
                        ZStack(alignment: .topLeading) {
                            MatchView(player1: matches[roundIndex][matchIndex].0,
                                      player2: matches[roundIndex][matchIndex].1)
                            
                            if roundIndex < matches.count - 1 {
                                Path { path in
                                    let midX = CGFloat(100)
                                    _ = CGFloat(40)
                                    let currentY = CGFloat(matchIndex * 160 + 40)
                                    let nextMatchIndex = matchIndex / 2
                                    let nextY = CGFloat(nextMatchIndex * 160 + 80)
                                    
                                    // Draw line from player1 to center
                                    path.move(to: CGPoint(x: midX, y: currentY - 20))
                                    path.addLine(to: CGPoint(x: midX + 50, y: currentY - 20))
                                    
                                    // Draw line from player2 to center
                                    path.move(to: CGPoint(x: midX, y: currentY + 20))
                                    path.addLine(to: CGPoint(x: midX + 50, y: currentY + 20))
                                    
                                    // Draw vertical connecting line
                                    path.move(to: CGPoint(x: midX + 50, y: currentY - 20))
                                    path.addLine(to: CGPoint(x: midX + 50, y: nextY))
                                    
                                    // Draw horizontal line to next match
                                    path.move(to: CGPoint(x: midX + 50, y: nextY))
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



