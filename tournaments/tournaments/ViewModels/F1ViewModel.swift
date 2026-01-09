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

            for race in newRaces {
                self.tournament.f1Race.append(race)
            }
        }

        // Zápis do MongoDB
        Task {
            for race in newRaces {
                try? await MongoDBManager.shared.insertF1Race([
                    "_id": race._id.stringValue,
                    "tournament_id": tournament._id.stringValue,
                    "name": name,
                    "country": country,
                    "laps": laps,
                    "date": date,
                    "raceNumber": raceNumber,
                    "player": race.player?.name ?? ""
                ])
            }
        }

        loadRaces()
    }
    
    private func parseFastestLap(_ s: String) -> Double {
        // Očakávame formát "min:sec:ms", napr. "1:15:836"
        let comps = s.split(separator: ":")
        // Musia byť presne 3 časti
        guard comps.count == 3 else {
            return Double.greatestFiniteMagnitude // nepoužiteľný reťazec
        }
        // Skúsime skonvertovať min, sec, ms na Double
        guard
            let minutes = Double(comps[0]),
            let seconds = Double(comps[1]),
            let milliseconds = Double(comps[2])
        else {
            return Double.greatestFiniteMagnitude
        }
        // Výpočet: min * 60 + sec + (ms / 1000)
        let totalSeconds = minutes * 60.0 + seconds + (milliseconds / 1000.0)
        return totalSeconds
    }

    
    func updateStandings() {
        guard let realm = realm else { return }

        // 1) Načítame všetky existujúce PlayerTable/TeamTable pre tento turnaj
        let allPlayerTables = realm.objects(F1PlayerTable.self)
            .filter("tournament == %@", tournament)
        let allTeamTables = realm.objects(F1TeamTable.self)
            .filter("tournament == %@", tournament)

        // 2) V write transakcii vyresetujeme body, wins, podiums, fastestLaps
        try? realm.write {
            for pt in allPlayerTables {
                pt.totalPoints = 0
                pt.wins = 0
                pt.podiums = 0
                pt.fastestLaps = 0
            }
            for tt in allTeamTables {
                tt.totalPoints = 0
                tt.wins = 0
                tt.podiums = 0
                tt.fastestLaps = 0
            }
        }

        // 3) Všetky preteky (F1Race) pre daný turnaj
        let allResults = realm.objects(F1Race.self)
            .filter("tournament == %@", tournament)

        // 4) V prvej fáze pripočítame body, wins, podiums
        try? realm.write {
            for result in allResults {
                guard let player = result.player else { continue }
                let teamName = player.team ?? ""
                if teamName.isEmpty { continue }

                // finalPos = buď 'finished' (ak je to reťazec s číslom) alebo 'position'
                let finalPos = Int(result.finished) ?? result.position ?? 9999
                let points = calculatePoints(position: finalPos)

                // ===== PLAYER TABLE =====
                if let existingPT = allPlayerTables.first(where: { $0.player == player }) {
                    existingPT.totalPoints += points

                    // Pódium: ak finalPos <= 3
                    if finalPos <= 3 { existingPT.podiums += 1 }
                    // Víťazstvo: ak finalPos == 1
                    if finalPos == 1 { existingPT.wins += 1 }

                } else {
                    // Neexistuje -> vytvoríme
                    let newPT = F1PlayerTable(player: player, totalPoints: points, tournament: tournament)
                    if finalPos <= 3 { newPT.podiums = 1 }
                    if finalPos == 1 { newPT.wins = 1 }
                    realm.add(newPT)
                }

                // ===== TEAM TABLE =====
                if let existingTT = allTeamTables.first(where: { $0.teamName == teamName }) {
                    existingTT.totalPoints += points
                    if finalPos <= 3 { existingTT.podiums += 1 }
                    if finalPos == 1 { existingTT.wins += 1 }
                } else {
                    let newTT = F1TeamTable(teamName: teamName, totalPoints: points, tournament: tournament)
                    if finalPos <= 3 { newTT.podiums = 1 }
                    if finalPos == 1 { newTT.wins = 1 }
                    realm.add(newTT)
                }
            }
        }

        // predpokladajme, že ste už vymazali / vynulovali staré polia
        // a pripočítali body za pozície v prvej fáze

        let racesGrouped = Dictionary(grouping: allResults, by: { $0.raceNumber })

        try? realm.write {
            for (_, raceGroup) in racesGrouped {
                // Nájdeme pretek (všetky F1Race s rovnakým raceNumber)
                // Najprv vyfiltrujeme len tie, ktoré majú aspoň nejaký reťazec v fastestLap
                let validResults = raceGroup.filter {
                    parseFastestLap($0.fastestLap) < Double.greatestFiniteMagnitude
                }
                // Potom hľadáme objekt s najmenšou hodnotou parseFastestLap
                guard let best = validResults.min(by: {
                    parseFastestLap($0.fastestLap) < parseFastestLap($1.fastestLap)
                }) else {
                    // v tomto preteku nikto nemá validnú fastestLap
                    continue
                }
                // best je F1Race s najlepším (najmenším) časom
                guard let bestPlayer = best.player else { continue }
                let bestTeamName = bestPlayer.team ?? ""

                // Zvýšime fastestLaps o 1
                if let existingPT = allPlayerTables.first(where: { $0.player == bestPlayer }) {
                    existingPT.fastestLaps += 1
                } else {
                    let newPT = F1PlayerTable(player: bestPlayer, totalPoints: 0, tournament: tournament)
                    newPT.fastestLaps = 1
                    realm.add(newPT)
                }

                // Tím
                if !bestTeamName.isEmpty,
                   let existingTT = allTeamTables.first(where: { $0.teamName == bestTeamName }) {
                    existingTT.fastestLaps += 1
                } else if !bestTeamName.isEmpty {
                    let newTT = F1TeamTable(teamName: bestTeamName, totalPoints: 0, tournament: tournament)
                    newTT.fastestLaps = 1
                    realm.add(newTT)
                }
            }
        }


        // 6) Napokon načítame výsledné záznamy do @Published polia
        loadStandings()

        // Zápis do MongoDB
        Task {
            try? await MongoDBManager.shared.updateTournament(
                id: tournament._id.stringValue,
                updates: [
                    "f1PlayerStandings": allPlayerTables.map { [
                        "player": $0.player?.name ?? "",
                        "points": $0.totalPoints,
                        "wins": $0.wins,
                        "podiums": $0.podiums,
                        "fastestLaps": $0.fastestLaps
                    ]},
                    "f1TeamStandings": allTeamTables.map { [
                        "team": $0.teamName,
                        "points": $0.totalPoints,
                        "wins": $0.wins,
                        "podiums": $0.podiums,
                        "fastestLaps": $0.fastestLaps
                    ]}
                ]
            )
        }
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
        loadRaces()
        updateStandings()
    }
}
