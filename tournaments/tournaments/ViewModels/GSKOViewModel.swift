//
//  GSKOViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 11.02.2025.
//

import Foundation
import RealmSwift

import SwiftUI

class GSKOViewModel: ObservableObject {
    @ObservedObject var viewModel: TournamentGenerateModel
    
    init(viewModel: TournamentGenerateModel) {
        self.viewModel = viewModel
    }
    
    var allResultsFilled: Bool {
        !viewModel.matches.contains { match in
            match.player1Score == 0 && match.player2Score == 0
        }
    }

    func proceedAfterAllResults() {
        print("All results are filled. Proceeding to the next step...")
        createKnockoutStage()
    }
    
    func createKnockoutStage() {
            guard let tournament = viewModel.tournament.settings.first else {
                print("Tournament settings not found")
                return
            }

            let advancingPerGroup = 2//tournament.advancingPerGroup  // Počet postupujúcich zo skupiny
            let groupsCount = 4 //viewModel.tournament.groupsCount    // Počet skupín
            var advancingPlayers: [Player] = []
            
        for groupIndex in 1...groupsCount {
                    let groupMatches = viewModel.matches.filter { $0.matchIndex == groupIndex } // Filtrujeme zápasy pre danú skupinu
                    var playerStats: [Player: TournamentTable] = [:]
                    
                    // 2. Naplníme tabuľku bodov pre hráčov v danej skupine
                    for match in groupMatches {
                        if let player1 = match.player1, let player2 = match.player2 {
                            if let table1 = viewModel.table.first(where: { $0.player == player1 }) {
                                playerStats[player1] = table1
                            }
                            if let table2 = viewModel.table.first(where: { $0.player == player2 }) {
                                playerStats[player2] = table2
                            }
                        }
                    }
                    
                    // 3. Zoradíme hráčov podľa bodov
                    let qualified = playerStats.sorted { $0.value.points > $1.value.points }
                                              .prefix(advancingPerGroup)
                                              .map { $0.key } // Extrahujeme iba hráčov
                    
                    advancingPlayers.append(contentsOf: qualified)
                }

            // 2. Zamiešame hráčov, aby boli v pavúkovi náhodne
            advancingPlayers.shuffle()
            
            // 3. Vytvoríme Knockout Stage zápasy
            var knockoutMatches: [Match] = []
            for i in stride(from: 0, to: advancingPlayers.count, by: 2) {
                if i + 1 < advancingPlayers.count {
                    let match = Match()
                    match.player1 = advancingPlayers[i]
                    match.player2 = advancingPlayers[i + 1]
                    match.fixturesRound = 1  // Prvé kolo KO fázy
                    match.tournament = viewModel.tournament
                    match.matchIndex = (i / 2) + 1
                    knockoutMatches.append(match)
                }
            }
            
            // 4. Uložíme zápasy do Realm databázy
            if let realm = RealmManager.shared.realm {
                try? realm.write {
                    realm.add(knockoutMatches)
                }
            }
            
            print("Knockout stage generated with \(knockoutMatches.count) matches!")
        }
}

