//
//  SingleElimination.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.

import SwiftUI
import RealmSwift

struct SingleEliminationView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @State private var showScoreDialog = false
    @State private var selectedMatch: TournamentMatch?
    @State private var rematchFlag = 0  // Defaultná hodnota
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            HStack(spacing: 100) {
                ForEach(0..<viewModel.EliminationRounds, id: \.self) { roundIndex in
                    VStack(spacing: 40) {
                        let matchesForRound = viewModel.matches
                            .filter {
                                $0.fixturesRound == roundIndex + 1 &&
                                (viewModel.tournament.type == "Group Stage and KO" ? $0.matchIndex != 0 : true)
                            }
                           .sorted { $0.matchIndex < $1.matchIndex }
                        
                        ForEach(0..<viewModel.matchesInSection[roundIndex], id: \.self) { matchIndex in
                            ZStack {
                                if matchIndex < matchesForRound.count {
                                    MatchViewv(
                                        match: matchesForRound[matchIndex],
                                        showScoreDialog: $showScoreDialog,
                                        selectedMatch: $selectedMatch,
                                        rematchFlag: $rematchFlag
                                    )
                                } else {
                                    MatchViewv(
                                        match: nil,
                                        showScoreDialog: $showScoreDialog,
                                        selectedMatch: $selectedMatch,
                                        rematchFlag: $rematchFlag
                                    )
                                }
                                
                                if roundIndex < viewModel.EliminationRounds - 1 {
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
        .sheet(isPresented: Binding(
            get: { showScoreDialog },
            set: { showScoreDialog = $0 }
        )) {
            if let match = selectedMatch {
                if match.tournament?.type == "Playoff" {
                    EditPlayoffDialogView(
                        match: match,
                        isPresented: $showScoreDialog,
                        playOffMatches: match.tournament?.playOFFMatches ?? 3,
                        onSave: viewModel.updateMatchScore
                    )
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EditModalDialogView(
                        match: match,
                        isPresented: $showScoreDialog,
                        rematchFlag: rematchFlag,
                        onSave: viewModel.updateMatchScore
                    )
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
        }
        .stroke(Color.green, lineWidth: 2)
    }
}

struct MatchViewv: View {
    var match: TournamentMatch?
    @Binding var showScoreDialog: Bool
    @Binding var selectedMatch: TournamentMatch?
    @Binding var rematchFlag: Int  // Posielame flag do hlavného view
    
    var body: some View {
        VStack(spacing: 8) {
            Text(match?.player1?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                if let match = match {
                    selectedMatch = match
                    showScoreDialog = true
                    rematchFlag = 0  // Prvý zápas
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
            
            if match?.rematchFlag == 1 {
                Button(action: {
                    if let match = match {
                        selectedMatch = match
                        showScoreDialog = true
                        rematchFlag = 1  // Odvetný zápas
                    }
                }) {
                    Text("\(match?.player1ScoreRematch ?? 0) - \(match?.player2ScoreRematch ?? 0)")
                        .font(.subheadline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Text(match?.player2?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            if let setsString = match?.setsString,
               !setsString.isEmpty,
               let t = match?.tournament,
               t.sport == "Tennis" || t.sport == "Hockey" {
                
                let sets = setsString.split(separator: ";").map { String($0) }
                
                HStack {
                    ForEach(sets, id: \.self) { setScore in
                        Text(setScore)
                            .font(.subheadline)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple, lineWidth: 2)
        )
        .frame(width: 300, height: 120)
    }
}
