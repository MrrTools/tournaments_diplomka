//
//  NewTournamentViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

//definition
//@Published checking swiftUI changes and refresh the view

import RealmSwift
import SwiftUI

class NewTournamentViewModel: ObservableObject {
    @Published var tournamentName: String = ""
    @Published var owner: String = ""
    @Published var selectedSport: String? = nil
    @Published var selectedType: String? = nil
    @Published var numberOfPlayers: Double = 2 {
        didSet {
            updatePlayersArray()
        }
    }
    @Published var riposeMateches: Bool = false
    @Published var numberOfRaces: Double = 3
    @Published var players: [String] = Array(repeating: "", count: 2)
    @Published var isEditing: Bool = false
    @Published var playerPhotos: [Int: UIImage] = [:]
    @Published var f1Teams: [String] = Array(repeating: "", count: 2)
    
    let sportTypes: [String: [String]] = [
        "Football": ["Single Elimination", "Double Elimination", "Round Robin", "Group Stage and KO"],
        "Hockey": ["Single Elimination", "Round Robin", "Playoff", "NHL", "Group Stage and KO"],
        "Tennis": ["Single Elimination"],
        "F1": ["Championship"]
    ]
    
    let onSave: () -> Void
    
    init(onSave: @escaping () -> Void) {
        self.onSave = onSave
    }
    
    private func updatePlayersArray() {
        let count = Int(numberOfPlayers)
        if players.count < count {
            players.append(contentsOf: Array(repeating: "", count: count - players.count))
            f1Teams.append(contentsOf: Array(repeating: "", count: count - f1Teams.count))
        } else if players.count > count {
            players.removeLast(players.count - count)
            f1Teams.removeLast(f1Teams.count - count)
        }
    }
    
    func saveTournament() {
        let players = self.players.enumerated().map { (index, name) -> Player in
            let photoData = self.playerPhotos[index]?.jpegData(compressionQuality: 1.0)
            let team = self.f1Teams.indices.contains(index) ? self.f1Teams[index] : ""
            return Player(name: name, team: team, photoData: photoData)
        }
        
        func generateStandings(players: [Player], tournament: Tournament) -> [TournamentTable] {
            return players.map { TournamentTable(player: $0, tournament: tournament) }
        }
        
        
        
        
        let tournament = Tournament(
            name: self.tournamentName,
            owner: self.owner,
            sport: self.selectedSport ?? "",
            type: self.selectedType ?? "",
            players: players,
            matches: [],
            table: [],
            settings: []
        )
        
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                realm.add(tournament)
               // let settings = TournamentSettings(tournament: tournament)
               // realm.add(settings)
            }
            
            onSave()
        }
        
        var matches: [Match] = []
        
        if self.selectedType == "Round Robin" {
            matches = generateRoundRobinMatches(players: players, tournament: tournament, riposeMateches: riposeMateches)
        } else if self.selectedType == "Single Elimination" || self.selectedType == "Double Elimination" {
            matches = generateElimination(players: players, tournament: tournament)
        }
        else if self.selectedType == "Group Stage and KO"{
            matches = generateGSKO(players: players, numberOfGroups: 4, advancingPerGroup: 2, groupMatchesCount: 1, tournament: tournament)
        }
        //let table: [TournamentTable] = generateStandings(players: players, tournament: tournament)
        let settings = TournamentSettings(tournament: tournament)
        
        //if let optional konstrukcia swift kde sa telo vykona ak nie je nill
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                tournament.matches.append(objectsIn: matches)
               // tournament.table.append(objectsIn: table)
                tournament.settings.append(settings)
                realm.add(tournament, update: .modified)
            }
        }
        
        onSave()
    }
}
