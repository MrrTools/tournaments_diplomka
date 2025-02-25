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
    @State private var rematchFlag = 0
    @State private var koFlag = true
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            HStack(spacing: 100) {
                ForEach(0..<viewModel.EliminationRounds, id: \.self) { roundIndex in
                    VStack(spacing: 90) {
                        let matchesForRound = getMatchesForRound(roundIndex)
                        let expectedMatchCount = viewModel.matchesInSection[safe: roundIndex] ?? 0
                        let isFinalRound = roundIndex + 1 == viewModel.EliminationRounds // 🔥 Finále je posledné kolo

                        ForEach(0..<expectedMatchCount, id: \.self) { matchIndex in
                            MatchViewv(
                                match: matchesForRound[safe: matchIndex],
                                showScoreDialog: $showScoreDialog,
                                selectedMatch: $selectedMatch,
                                rematchFlag: $rematchFlag,
                                riposeFinal: viewModel.tournament.riposeFinal ?? false,
                                riposeKnockout: viewModel.tournament.riposeKnockOut ?? false,
                                isFinalMatch: isFinalRound // 🔥 Informácia o finálovom zápase
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle("Tournament Bracket", displayMode: .inline)
        .sheet(isPresented: Binding(
            get: { showScoreDialog && selectedMatch != nil },
            set: { newValue in
                if !newValue { selectedMatch = nil }
                showScoreDialog = newValue
            }
        )) {
            if let match = selectedMatch {
                if match.tournament?.type == "Playoff" {
                    EditPlayoffDialogView(
                        match: match,
                        isPresented: $showScoreDialog,
                        playOffMatches: match.tournament?.playOFFMatches ?? 3,
                        onSave: viewModel.updateMatchScore
                    )
                } else {
                    EditModalDialogView(
                        match: match,
                        isPresented: $showScoreDialog,
                        rematchFlag: rematchFlag,
                        koFlag: koFlag,
                        onSave: viewModel.updateMatchScore
                    )
                }
            }
        }
    }

    /// 🔥 Získať zápasy pre dané kolo
    private func getMatchesForRound(_ roundIndex: Int) -> [TournamentMatch] {
        viewModel.matches
            .filter { $0.fixturesRound == roundIndex + 1 && (viewModel.tournament.type == "Group Stage and KO" ? $0.matchIndex != 0 : true) }
            .sorted { $0.matchIndex < $1.matchIndex }
    }
}

/// ✅ **Match View so správnym `Binding` pre `sheet`**
struct MatchViewv: View {
    var match: TournamentMatch?
    @Binding var showScoreDialog: Bool
    @Binding var selectedMatch: TournamentMatch?
    @Binding var rematchFlag: Int
    let riposeFinal: Bool
    let riposeKnockout: Bool
    let isFinalMatch: Bool // 🔥 Informácia, či je to finálový zápas

    var body: some View {
        VStack(spacing: 8) {
            Text(match?.player1?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { openScoreDialog(for: match, rematch: 0) }) {
                ScoreButtonContent(score: match?.player1Score ?? 0, vsScore: match?.player2Score ?? 0)
            }

            // 🔥 Podmienka pre rematch button:
            // Ak je `riposeFinal` true a `riposeKnockout` false, zobrazí sa len vo finále (posledné kolo)
            if match?.rematchFlag == 1 || riposeKnockout || (riposeFinal && isFinalMatch) {
                Button(action: { openScoreDialog(for: match, rematch: 1) }) {
                    ScoreButtonContent(score: match?.player1ScoreRematch ?? 0, vsScore: match?.player2ScoreRematch ?? 0)
                }
            }

            Text(match?.player2?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let setsString = match?.setsString, !setsString.isEmpty {
                SetsView(setsString: setsString, sport: match?.tournament?.sport)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple, lineWidth: 2))
        .frame(width: 300, height: 120)
    }
    
    /// Otvorí dialógové okno pre skóre zápasu
    private func openScoreDialog(for match: TournamentMatch?, rematch: Int) {
        if let match = match {
            selectedMatch = match
            showScoreDialog = true
            rematchFlag = rematch
        }
    }
}

/// ✅ **Tlačidlo pre skóre zápasu**
struct ScoreButtonContent: View {
    let score: Int
    let vsScore: Int

    var body: some View {
        Text("\(score) - \(vsScore)")
            .font(.subheadline)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

/// ✅ **Zobrazenie setov pre Tennis / Hockey**
struct SetsView: View {
    let setsString: String
    let sport: String?

    var body: some View {
        if let sport = sport, sport == "Tennis" || sport == "Hockey" {
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
}

/// ✅ **Bezpečné načítanie indexov v poli**
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
