//
//  GSKOView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 09.02.2025.
//

import SwiftUI
import RealmSwift

struct GSKOView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    /// Počet skupín, ktorý musíte poznať (napr. z nastavení turnaja)
    let numberOfGroups: Int
    
    @State private var selectedGroupIndex = 0
    
    var body: some View {
        VStack {
            // Názov turnaja
            Text(viewModel.tournament.name)
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            // Segmented picker pre prepínanie medzi skupinami
            Picker("Skupina", selection: $selectedGroupIndex) {
                ForEach(0..<numberOfGroups, id: \.self) { index in
                    Text("Group \(Character(UnicodeScalar(65 + index)!))")
                        .tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Obsah vybratej skupiny
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Tabuľka pre vybranú skupinu
                    GroupTableView(tableEntries: groupTableEntries)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Zoznam zápasov pre vybranú skupinu
                    GroupMatchesView(matches: groupMatches)
                }
                .padding()
            }
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
        .navigationTitle("Skupinová fáza")
        .onAppear {
            // Pri načítaní view načítame aktuálne tabuľkové údaje a zápasy
            viewModel.loadTable()
            viewModel.loadMatches()
        }
    }
    
    /// Predpokladáme, že hráči sú rovnomerne rozdelení do skupín.
    /// Ak je celkový počet hráčov turnaja deliteľný počtom skupín, každý tím má rovnaký počet tabuľkových záznamov.
    var groupTableEntries: [TournamentTable] {
        let totalPlayers = viewModel.tournament.players.count
        let playersPerGroup = totalPlayers / numberOfGroups
        let start = selectedGroupIndex * playersPerGroup
        let end = start + playersPerGroup
        if viewModel.table.count >= end {
            return Array(viewModel.table[start..<end])
        } else {
            return []
        }
    }
    
    /// Skupinové zápasy – predpokladáme, že v skupinovej fáze majú zápasy `fixturesRound` od 1 do numberOfGroups.
    var groupMatches: [Match] {
        viewModel.matches.filter { $0.fixturesRound == selectedGroupIndex + 1 }
    }
}

struct GroupTableView: View {
    let tableEntries: [TournamentTable]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Tabuľka")
                .font(.headline)
            ForEach(tableEntries, id: \.id) { entry in
                HStack {
                    Text(entry.player?.name ?? "TBD")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Points: \(entry.points)")
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct GroupMatchesView: View {
    let matches: [Match]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Zápasy")
                .font(.headline)
            ForEach(matches, id: \.id) { match in
                VStack(alignment: .leading) {
                    HStack {
                        Text(match.player1?.name ?? "Team 1")
                        Text("vs")
                        Text(match.player2?.name ?? "Team 2")
                    }
                    .font(.subheadline)
                    Text("Kolo: \(match.fixturesRound)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
