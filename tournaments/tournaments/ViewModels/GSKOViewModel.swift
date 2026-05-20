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
        // Nenačítavame tu dáta, lebo viewModel ešte nemá načítané matches
        // checkIfKnockoutStageExists() a filterData() sa zavolajú v GSKOView.loadData()
    }
    
    //Aktualizuje filtrované zápasy a tabuľku pre vybranú skupinu
    func filterData() {
        filteredTable = viewModel.table.filter { $0.groupIndex == selectedGroupIndex + 1 }
        objectWillChange.send()
    }
    
    // Automaticky skontroluje, či knockout zápasy už existujú
    func checkIfKnockoutStageExists() {
        // Len nastavíme či komponenty existujú, NEprepíname automaticky showKnockoutStage
        showHideComponets = viewModel.matches.contains(where: { $0.groupIndex == 0 })
    }
    
    //Podmienka správne kontroluje stav turnaja
    var allResultsFilled: Bool {
        // Získame všetky group stage zápasy (groupIndex != 0)
        let groupStageMatches = viewModel.matches.filter { $0.groupIndex != 0 }

        // Ak nie sú žiadne group stage zápasy, nemôžeme pokračovať
        guard !groupStageMatches.isEmpty else { return false }

        // Skontrolujeme, či sú VŠETKY group stage zápasy dokončené
        // Zápas je dokončený ak je označený ako "played"
        let allCompleted = groupStageMatches.allSatisfy { $0.isPlayed }

        return allCompleted
    }
    
    //Generuje Knockout Stage len raz
    func proceedAfterAllResults() {
        // Kontrola či KO zápasy už neexistujú
        let koMatchesExist = viewModel.matches.contains(where: { $0.groupIndex == 0 })
        guard !koMatchesExist else {
            // KO zápasy už existujú, len prepneme na KO view
            print("DEBUG: KO matches already exist, switching to KO view")
            showKnockoutStage = true
            checkIfKnockoutStageExists()
            return
        }

        // Kontrola či sú všetky group stage zápasy dokončené
        let groupStageMatches = viewModel.matches.filter { $0.groupIndex != 0 }
        let completedMatches = groupStageMatches.filter { $0.isPlayed }
        print("DEBUG: Group stage matches: \(groupStageMatches.count), completed: \(completedMatches.count)")

        guard allResultsFilled else {
            print("DEBUG: Not all results filled, cannot create KO stage")
            return
        }

        print("DEBUG: Creating KO stage...")
        // Vytvoríme KO stage
        createKnockoutStage(advancingPerGroup: viewModel.tournament.numberOfAdvancePlayers ?? 2, groupsCount: viewModel.tournament.numberOfGroups ?? 4)
        showKnockoutStage = true
        checkIfKnockoutStageExists()
        self.viewModel.loadMatches()
        self.viewModel.objectWillChange.send()
    }
    
    // Generovanie KO fázy
    func createKnockoutStage(advancingPerGroup: Int, groupsCount: Int) {
        var advancingPlayers: [Player] = []

        for groupIndex in 1...groupsCount {
            // Získame tabuľku pre danú skupinu a zoradíme hráčov
            let groupTable = viewModel.table
                .filter { $0.groupIndex == groupIndex }
                .sorted { table1, table2 in
                    // Primárne zoradenie: body
                    if table1.points != table2.points {
                        return table1.points > table2.points
                    }
                    // Sekundárne: skóre rozdielu
                    let diff1 = table1.goalsScored - table1.goalsConceded
                    let diff2 = table2.goalsScored - table2.goalsConceded
                    if diff1 != diff2 {
                        return diff1 > diff2
                    }
                    // Terciárne: počet vstrelených gólov
                    if table1.goalsScored != table2.goalsScored {
                        return table1.goalsScored > table2.goalsScored
                    }
                    // Ak je všetko rovnaké, ponechaj pôvodné poradie
                    return true
                }

            // Vyberieme top X hráčov z tejto skupiny
            let qualified = groupTable
                .prefix(advancingPerGroup)
                .compactMap { $0.player }

            advancingPlayers.append(contentsOf: qualified)
        }

        // Overíme, že máme správny počet hráčov
        let expectedPlayers = groupsCount * advancingPerGroup
        guard advancingPlayers.count == expectedPlayers else {
            print("ERROR: Expected \(expectedPlayers) players, got \(advancingPlayers.count)")
            return
        }

        let matches = generateElimination(players: advancingPlayers, tournament: viewModel.tournament)

        if let realm = RealmManager.shared.realm {
            RealmManager.safeWrite(realm, operation: "createKnockoutStage") {
                viewModel.tournament.matches.append(objectsIn: matches)
                realm.add(viewModel.tournament, update: .modified)
            }
        }
        checkIfKnockoutStageExists()
    }
}
