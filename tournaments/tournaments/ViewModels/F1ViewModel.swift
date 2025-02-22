//
//  F1ViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 21.02.2025.
//

import Foundation
import RealmSwift

class F1ViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    private var realm: Realm?
    
    @Published var races: [F1Race] = []
    @Published var playerStandings: [F1PlayerTable] = []
    @Published var teamStandings: [F1TeamTable] = []
    @Published var tournament: Tournament
    
    init(tournament: Tournament) {
        self.tournament = tournament
        realm = RealmManager.shared.realm
        loadRaces()
        loadStandings()
    }
    
    func loadRaces() {
        guard let realm = realm else { return }
        races = Array(realm.objects(F1Race.self).filter("tournament == %@", tournament))
    }
    
    func getRace(for index: Int) -> F1Race? {
        return races.first(where: { $0.raceNumber == index })
    }
    
    func getRaceResults(for race: F1Race) -> [F1Race] {
        return races.filter { $0.raceNumber == race.raceNumber }
    }
    
    func loadStandings() {
        guard let realm = realm else { return }
        
        playerStandings = Array(realm.objects(F1PlayerTable.self)
            .filter("tournament == %@", tournament)
            .sorted(byKeyPath: "totalPoints", ascending: false))
        
        teamStandings = Array(realm.objects(F1TeamTable.self)
            .filter("tournament == %@", tournament)
            .sorted(byKeyPath: "totalPoints", ascending: false))
    }
    
    func addRace(name: String, country: String, laps: Int, date: Date, raceNumber: Int) {
        guard let realm = realm else { return }
        
        let allPlayers = realm.objects(F1PlayerTable.self).filter("tournament == %@", tournament)
        let players = allPlayers.compactMap { $0.player }
        
        
        let newRaces: [F1Race] = players.map { player in
            return F1Race(
                name: name,
                country: country,
                laps: laps,
                date: date,
                player: player,
                position: nil,
                startPosition: 0,
                fastestLap: "",
                pitStops: 0,
                finished: "",
                raceNumber: raceNumber,
                tournament: self.tournament
            )
        }
        
        // 2) Potom ich všetky naraz pridáme do Realm
        try? realm.write {
            realm.add(newRaces)
        }
        
        loadRaces()
        //updateStandings()
    }
    
    func updateStandings() {
        guard let realm = realm else { return }
        
        var playerPoints: [Player: Int] = [:]
        var teamPoints: [String: Int] = [:]
        
        let allResults = realm.objects(F1Race.self).filter("tournament == %@", tournament)
        
        for result in allResults {
            guard let player = result.player, let team = player.team, !team.isEmpty else { continue }
            
            let points = calculatePoints(position: result.position)
            playerPoints[player, default: 0] += points
            teamPoints[team, default: 0] += points
        }
        
        try? realm.write {
            realm.delete(realm.objects(F1PlayerTable.self).filter("tournament == %@", tournament))
            realm.delete(realm.objects(F1TeamTable.self).filter("tournament == %@", tournament))
            
            for (player, points) in playerPoints {
                let standing = F1PlayerTable(player: player, totalPoints: points, tournament: tournament)
                realm.add(standing)
            }
            
            for (team, points) in teamPoints {
                let teamStanding = F1TeamTable(teamName: team, totalPoints: points, tournament: tournament)
                realm.add(teamStanding)
            }
        }
        
        loadStandings()
    }
    
    private func calculatePoints(position: Int?) -> Int {
        guard let pos = position else { return 0 }
        switch pos {
        case 1: return 25
        case 2: return 18
        case 3: return 15
        case 4: return 12
        case 5: return 10
        case 6: return 8
        case 7: return 6
        case 8: return 4
        case 9: return 2
        case 10: return 1
        default: return 0
        }
    }
    
    func updateRace(_ race: F1Race,
                    position: Int? = nil,
                    pitStops: Int? = nil,
                    fastestLap: String? = nil,
                    startPosition: Int? = nil,
                    finished: String? = nil)
    {
        guard let realm = realm else { return }
        try? realm.write {
            if let pos = position {
                race.position = pos
            }
            if let stops = pitStops {
                race.pitStops = stops
            }
            if let lap = fastestLap {
                race.fastestLap = lap
            }
            if let startPos = startPosition {
                race.startPosition = startPos
            }
            if let fin = finished {
                race.finished = String(fin) // Ak `finished` v modele je String
                // alebo ak je to priamo Int, tak race.finished = fin
            }
        }
        // updateStandings() ak je treba
    }
}
