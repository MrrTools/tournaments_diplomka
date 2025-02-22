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
    @Published var groupNumber: Int? = nil
    @Published var qualifiedToNextRound: Int? = nil
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
    @Published var playOFFMatches: Int? = nil
    
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
        
        let isF1 = selectedSport == "F1"

        let tournament = Tournament(
            name: self.tournamentName,
            owner: self.owner,
            sport: self.selectedSport ?? "",
            type: self.selectedType ?? "",
            groupNumber: self.groupNumber,
            playOFFMatches: self.playOFFMatches,
            qualifiedToNextRound: self.qualifiedToNextRound,
            numberOfRaces: isF1 ? Int(numberOfRaces) : nil,  // 🔥 Uloženie počtu pretekov pre F1
            players: players,
            matches: [],
            table: [],
            settings: [],
            f1Race: [],
            f1TeamTable: [],
            f1PlayerTable: []
        )
        
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                realm.add(tournament)
            }
            
            onSave()
        }
        
        if isF1 {
            generateF1Standings(tournament: tournament, players: players)
        } else {
            generateStandardTournament(tournament: tournament, players: players)
        }
        
        onSave()
    }
    
    // ✅ GENEROVANIE F1 STANDINGS (BEZ PRETEKOV)
    private func generateF1Standings(tournament: Tournament, players: [Player]) {
        let driverStandings = players.map { F1PlayerTable(player: $0, tournament: tournament) }
        
        let teamStandings = Dictionary(grouping: players, by: { $0.team! }).map { (team, drivers) in
            F1TeamTable(teamName: team, tournament: tournament)
        }
        
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                tournament.f1PlayerTable.append(objectsIn: driverStandings)
                tournament.f1TeamTable.append(objectsIn: teamStandings)
                realm.add(tournament, update: .modified)
            }
        }
    }
    
    // ✅ GENEROVANIE ŠTANDARDNÝCH TURNOS (PRE OSTATNÉ ŠPORTY)
    private func generateStandardTournament(tournament: Tournament, players: [Player]) {
        var matches: [TournamentMatch] = []
        
        switch selectedType {
        case "Round Robin":
            matches = generateRoundRobinMatches(players: players, tournament: tournament, riposeMateches: riposeMateches)
        case "Single Elimination", "Double Elimination", "Playoff":
            matches = generateElimination(players: players, tournament: tournament)
        case "Group Stage and KO":
            matches = generateGSKO(players: players, numberOfGroups: 4, advancingPerGroup: 2, tournament: tournament, groupMatchesCount: 1)
        default:
            break
        }
        
        let table: [TournamentTable] = players.map { TournamentTable(player: $0, tournament: tournament) }
        let settings = TournamentSettings(tournament: tournament)

        if let realm = RealmManager.shared.realm {
            try? realm.write {
                tournament.matches.append(objectsIn: matches)
                tournament.table.append(objectsIn: table)
                tournament.settings.append(settings)
                realm.add(tournament, update: .modified)
            }
        }
    }
}
