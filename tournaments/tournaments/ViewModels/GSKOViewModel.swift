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
    @Published var showKnockoutStage = false
    @Published var showHideComponets = false
    @Published var selectedGroupIndex: Int = 0
    @Published var filteredTable: [TournamentTable] = []
    
    
    init(viewModel: TournamentGenerateModel) {
        self.viewModel = viewModel
        checkIfKnockoutStageExists()
        filterData()
    }
    
    //Aktualizuje filtrované zápasy a tabuľku pre vybranú skupinu
    func filterData() {
        filteredTable = viewModel.table.filter { $0.groupIndex == selectedGroupIndex + 1 }
        objectWillChange.send()
    }
    
    // Automaticky skontroluje, či knockout zápasy už existujú
    func checkIfKnockoutStageExists() {
        showKnockoutStage = viewModel.matches.contains(where: { $0.groupIndex == 0 })
        showHideComponets = viewModel.matches.contains(where: { $0.groupIndex == 0 })
    }
    
    //Podmienka správne kontroluje stav turnaja
    var allResultsFilled: Bool {
        switch (viewModel.matches.contains { $0.groupIndex != 0 && ($0.player1Score == 0 && $0.player2Score == 0) },
                showKnockoutStage) {
        case (true, _):
            return false
        case (false, true):
            return false
        case (false, false):
            return true
        }
    }
    
    //Generuje Knockout Stage len raz
    func proceedAfterAllResults() {
        guard !showKnockoutStage else { return }
        createKnockoutStage(advancingPerGroup: viewModel.tournament.numberOfAdvancePlayers ?? 2, groupsCount: viewModel.tournament.numberOfGroups ?? 4)
        checkIfKnockoutStageExists()
        self.viewModel.loadMatches()
        self.viewModel.objectWillChange.send()
    }
    
    // Generovanie KO fázy
    func createKnockoutStage(advancingPerGroup: Int, groupsCount: Int) {
        var advancingPlayers: [Player] = []
        
        for groupIndex in 1...groupsCount {
            let groupMatches = viewModel.matches.filter { $0.groupIndex == groupIndex }
            var playerStats: [Player: TournamentTable] = [:]
            
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
            
            let qualified = playerStats.sorted { $0.value.points > $1.value.points }
                .prefix(advancingPerGroup)
                .map { $0.key }
            
            advancingPlayers.append(contentsOf: qualified)
        }
        
        let matches = generateElimination(players: advancingPlayers, tournament: viewModel.tournament)
        
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                viewModel.tournament.matches.append(objectsIn: matches)
                realm.add(viewModel.tournament, update: .modified)
            }
        }
        checkIfKnockoutStageExists()
    }
}
