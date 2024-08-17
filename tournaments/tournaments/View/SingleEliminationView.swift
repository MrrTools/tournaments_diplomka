//
//  SingleElimination.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//SingleElimination

//
//  SingleElimination.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//SingleElimination

import SwiftUI
import RealmSwift

struct SingleEliminationView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @State private var showScoreDialog = false
    @State private var selectedMatch: Match?
    
    var rounds: Int = 3
    var matchesInSection: [Int] = [4, 2, 1]
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            HStack(spacing: 100) {
                ForEach(0..<rounds, id: \.self) { roundIndex in
                    VStack(spacing: 40) {
                        let matchesForRound = viewModel.matches.filter { $0.fixturesRound == roundIndex + 1 }
                        
                        ForEach(0..<matchesInSection[roundIndex], id: \.self) { matchIndex in
                            ZStack {
                                if roundIndex == 0 && matchIndex < matchesForRound.count {
                                    MatchViewv(match: matchesForRound[matchIndex], showScoreDialog: $showScoreDialog, selectedMatch: $selectedMatch)
                                } else {
                                    MatchViewv(match: nil, showScoreDialog: $showScoreDialog, selectedMatch: $selectedMatch) // Zobrazí TBD
                                }
                                
                                if roundIndex < rounds - 1 {
                                    drawLine(matchIndex: matchIndex)
                                }
                            }
                        }
                    }
                }
            }
            
            .padding()
            
        }
        .navigationBarTitle("Tournament Bracket", displayMode: .inline)
        .sheet(isPresented: Binding(            get: { showScoreDialog },
                                                set: { showScoreDialog = $0 }
                                   ))
        {
            if let match = selectedMatch {
                EditModalDialogView(match: match, isPresented: $showScoreDialog, onSave: viewModel.updateMatchScore)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            
        }
    }

    @ViewBuilder
    func drawLine(matchIndex: Int) -> some View {
        Path { path in
            let midX = CGFloat(180)
            let currentY = CGFloat(60)
            let spacing = CGFloat(40)
            let nextY = CGFloat(matchIndex / 2 * Int(currentY + spacing) + Int(currentY / 2))
            // Zde můžete přidat logiku pro kreslení čar mezi zápasy
        }
        .stroke(Color.green, lineWidth: 2)
    }
}

struct MatchViewv: View {
    var match: Match?
    @Binding var showScoreDialog: Bool
    @Binding var selectedMatch: Match?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(match?.player1?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                if let match = match {
                    selectedMatch = match
                    showScoreDialog = true
                }
            }) {
                Text("\(match?.player1Score ?? 0) - \(match?.player2Score ?? 0)")
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Text(match?.player2?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple, lineWidth: 2)
        )
        .frame(width: 200, height: 100)  // Adjusted width and height to fit the new layout
    }
}
