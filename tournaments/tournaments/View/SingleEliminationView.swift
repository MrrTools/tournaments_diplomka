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
    @State private var selectedBracket = 0

    private var isLoserBracket: Bool { viewModel.tournament.type == "Loser Bracket" }
    private var bracketRounds: Int {
        if !isLoserBracket { return viewModel.EliminationRounds }
        switch selectedBracket {
        case -1: return max(0, 2 * viewModel.EliminationRounds - 2)
        case -2: return 2
        default: return viewModel.EliminationRounds
        }
    }
    
    var body: some View {
        ZStack {
            TournamentBackgroundView(backgroundImageData: viewModel.tournament.backgroundImageData)

            // Content
            VStack(spacing: 8) {
                if isLoserBracket {
                    Picker("Bracket", selection: $selectedBracket) {
                        Text("Winners").tag(0)
                        Text("Losers").tag(-1)
                        Text("Final").tag(-2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                GeometryReader { geometry in
                    let cardWidth = min(250.0, max(190.0, geometry.size.width - 40))
                    ScrollView([.horizontal, .vertical]) {
                        bracketContent(cardWidth: cardWidth)
                            .padding(20)
                    }
                }
            }
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
    
    // Získať zápasy pre dané kolo
    private func getMatchesForRound(_ roundIndex: Int) -> [TournamentMatch] {
        if isLoserBracket {
            let stage = selectedBracket == -2 ? -2 - roundIndex : selectedBracket
            let round = selectedBracket == -2 ? 1 : roundIndex + 1
            return viewModel.matches
                .filter { $0.groupIndex == stage && $0.fixturesRound == round }
                .sorted { $0.matchIndex < $1.matchIndex }
        }
        return viewModel.matches
            .filter { $0.fixturesRound == roundIndex + 1 && (viewModel.tournament.type == "Group Stage and KO" ? $0.matchIndex != 0 : true) }
            .sorted { $0.matchIndex < $1.matchIndex }
    }

    private func bracketContent(cardWidth: CGFloat) -> some View {
        let columns = (0..<bracketRounds).map(getMatchesForRound)
        let firstCount = max(1, columns.first?.count ?? 1)
        let step: CGFloat = 148
        let columnWidth = cardWidth + 64
        let contentHeight = CGFloat(firstCount) * step + 44

        return ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                guard columns.count > 1 else { return }
                for column in 0..<(columns.count - 1) {
                    let current = columns[column]
                    let next = columns[column + 1]
                    guard !current.isEmpty, !next.isEmpty else { continue }
                    for slot in current.indices {
                        let target = min(next.count - 1, slot * next.count / current.count)
                        let y1 = 44 + (CGFloat(slot) + 0.5) * contentHeight / CGFloat(current.count)
                        let y2 = 44 + (CGFloat(target) + 0.5) * contentHeight / CGFloat(next.count)
                        let x1 = CGFloat(column) * columnWidth + cardWidth
                        let x2 = CGFloat(column + 1) * columnWidth
                        var path = Path()
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: CGPoint(x: (x1 + x2) / 2, y: y1))
                        path.addLine(to: CGPoint(x: (x1 + x2) / 2, y: y2))
                        path.addLine(to: CGPoint(x: x2, y: y2))
                        context.stroke(path, with: .color(.purple.opacity(0.65)), lineWidth: 2)
                    }
                }
            }
            ForEach(columns.indices, id: \.self) { column in
                let games = columns[column]
                Text(selectedBracket == -2 ? (column == 0 ? "Grand final" : "Reset if needed") : "Round \(column + 1)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: cardWidth)
                    .offset(x: CGFloat(column) * columnWidth)
                ForEach(games.indices, id: \.self) { slot in
                    let game = games[slot]
                    let centerY = 44 + (CGFloat(slot) + 0.5) * contentHeight / CGFloat(max(1, games.count))
                    MatchViewv(
                        match: game,
                        showScoreDialog: $showScoreDialog,
                        selectedMatch: $selectedMatch,
                        rematchFlag: $rematchFlag,
                        riposeFinal: !isLoserBracket && (viewModel.tournament.riposeFinal ?? false),
                        riposeKnockout: !isLoserBracket && (viewModel.tournament.riposeKnockOut ?? false),
                        isFinalMatch: column + 1 == bracketRounds,
                        cardWidth: cardWidth
                    )
                    .offset(x: CGFloat(column) * columnWidth, y: centerY - 60)
                }
            }
        }
        .frame(width: CGFloat(max(1, columns.count)) * columnWidth, height: contentHeight + 88, alignment: .topLeading)
    }
}

//Match View so správnym `Binding` pre `sheet`
struct MatchViewv: View {
    var match: TournamentMatch?
    @Binding var showScoreDialog: Bool
    @Binding var selectedMatch: TournamentMatch?
    @Binding var rematchFlag: Int
    let riposeFinal: Bool
    let riposeKnockout: Bool
    let isFinalMatch: Bool // Informácia, či je to finálový zápas
    var cardWidth: CGFloat = 250
    
    var body: some View {
        VStack(spacing: 8) {
            Text(match?.player1?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            Button(action: { openScoreDialog(for: match, rematch: 0) }) {
                ScoreButtonContent(
                    score: match?.player1Score ?? 0,
                    vsScore: match?.player2Score ?? 0,
                    isPlayed: match?.isPlayed ?? false
                )
            }
            .disabled(match?.player1 == nil || match?.player2 == nil || (match?.groupIndex == -3 && match?.player1 == nil))
            
            //  Podmienka pre rematch button:
            // Ak je `riposeFinal` true a `riposeKnockout` false, zobrazí sa len vo finále (posledné kolo)
            if match?.rematchFlag == 1 || riposeKnockout || (riposeFinal && isFinalMatch) {
                Button(action: { openScoreDialog(for: match, rematch: 1) }) {
                    ScoreButtonContent(
                        score: match?.player1ScoreRematch ?? 0,
                        vsScore: match?.player2ScoreRematch ?? 0,
                        isPlayed: match?.isRematchPlayed ?? false
                    )
                }
            }
            
            Text(match?.player2?.name ?? "TBD")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.white)
            
            if let setsString = match?.setsString, !setsString.isEmpty {
                SetsView(setsString: setsString, sport: match?.tournament?.sport)
            }
        }
        .padding(8)
        .background((match?.isPlayed ?? false) ? Color.purple.opacity(0.2) : Color.black.opacity(0.8))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple, lineWidth: 2))
        .frame(width: cardWidth, height: 120)
    }
    
    // Otvorí dialógové okno pre skóre zápasu
    private func openScoreDialog(for match: TournamentMatch?, rematch: Int) {
        if let match = match {
            selectedMatch = match
            showScoreDialog = true
            rematchFlag = rematch
        }
    }
}

// Tlačidlo pre skóre zápasu
struct ScoreButtonContent: View {
    let score: Int
    let vsScore: Int
    let isPlayed: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Indikátor dokončenia zápasu
            Image(systemName: isPlayed ? "checkmark.square.fill" : "square")
                .foregroundColor(isPlayed ? .purple : .gray)
            
            Text("\(score) - \(vsScore)")
                .font(.subheadline)
        }
        .padding()
        .background(isPlayed ? Color.purple.opacity(0.4) : Color.gray.opacity(0.4))
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}

//Zobrazenie setov pre Tennis a zapasy playoff
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

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
