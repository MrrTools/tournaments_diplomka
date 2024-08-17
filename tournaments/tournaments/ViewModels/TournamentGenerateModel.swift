//
//  RoundRobinViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//

import SwiftUI
import RealmSwift

class TournamentGenerateModel: ObservableObject {
    @Published var tournament: Tournament
    @Published var table: [TournamentTable] = []
    @Published var matches: [Match] = []
    @Published var selectedRound: Int = 1 {
        didSet {
            loadMatches()
            loadTable()
        }
    }
    private let realm: Realm
    
    init(tournament: Tournament) {
        self.tournament = tournament
        realm = RealmManager.shared.realm!
        
        loadMatches()
        loadTable()
    }

    var rounds: [[Match]] {
        var rounds: [[Match]] = []
        print("Number of Rounds: \(numberOfRounds)")
        for round in 1...numberOfRounds {
            let matchesInRound = matches.filter { $0.fixturesRound == round }
            rounds.append(matchesInRound)
        }
        return rounds
    }

    var matchesForSelectedRound: [Match] {
        rounds[selectedRound - 1]
    }

    var numberOfRounds: Int {
        return matches.map { $0.fixturesRound }.max() ?? 0
    }
    
    func loadMatches() {
        let matches = realm.objects(Match.self).filter("tournament == %@", tournament)
        self.matches = Array(matches)
        objectWillChange.send()
    }
    
    func loadTable() {
        let table = realm.objects(TournamentTable.self).filter("tournament == %@", tournament)
        self.table = Array(table)
        objectWillChange.send()
     }
    
    func updateMatchScore(match: Match, player1Score: Int, player2Score: Int) {
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                match.player1Score = player1Score
                match.player2Score = player2Score
                
                realm.add(match, update: .modified)
                
            }
            updateTable(for: match, player1Score: player1Score, player2Score: player2Score)
            loadMatches()
            loadTable()
            objectWillChange.send()
        }
    }

    
     func updateTable(for match: Match, player1Score: Int, player2Score: Int) {
         guard let settings = tournament.settings.first else {
             print("Tournament settings not found")
             return
         }

        let player1 = match.player1!
        let player2 = match.player2!
        
        if let player1Table = tournament.table.first(where: { $0.player == player1 }) {
            if let player2Table = tournament.table.first(where: { $0.player == player2 }) {
                if let realm = RealmManager.shared.realm {
                    try? realm.write {
                        if player1Score > player2Score {
                            player1Table.wins += 1
                            player1Table.points += settings.winPoints + settings.losePoints
                            player2Table.losses += 1
                        } else if player1Score < player2Score {
                            player2Table.wins += 1
                            player2Table.points += settings.winPoints + settings.losePoints
                            player1Table.losses += 1
                        } else {
                            player1Table.draws += 1
                            player2Table.draws += 1
                            player1Table.points += settings.drawPoints
                            player2Table.points += settings.drawPoints
                        }
                        player1Table.goalsScored += player1Score
                        player1Table.goalsConceded += player2Score
                        player2Table.goalsScored += player2Score
                        player2Table.goalsConceded += player1Score
                        
                        realm.add(player1Table, update: .modified)
                        realm.add(player2Table, update: .modified)
                    }
                }
            }
        }
    }
}

// Generování Round Robin zápasů a jejich ukládání do MongoDB Realm
func generateRoundRobinMatches(players: [Player], tournament: Tournament, riposeMateches: Bool) -> [Match] {
    let matches: [Match] = []
    var players = players
    
    // Pokud je počet týmů lichý, přidejte "BYE"
    if players.count % 2 != 0 {
        players.append(Player(name: "BYE"))
    }

    for i in 1..<players.count {
        for j in 0..<players.count / 2 {
            let homeTeam = players[j]
            let awayTeam = players[players.count - 1 - j]
            print("Round: \(i) Home: \(homeTeam.name) Away: \(awayTeam.name)")
            if homeTeam.name == "BYE" || awayTeam.name == "BYE" {
                continue
            }
            let match = Match()
            match.player1 = homeTeam
            match.player2 = awayTeam
            match.fixturesRound = i
            match.tournament = tournament
            
            
            // Použití RealmManager pro uložení turnaje
            if let realm = RealmManager.shared.realm {
                try? realm.write {
                    realm.add(match)
                }
            }

            
            // odvety
            if riposeMateches {
                 let riposeMatch = Match()
                riposeMatch.player1 = awayTeam
                riposeMatch.player2 = homeTeam
                riposeMatch.fixturesRound = players.count - 1 + i
                riposeMatch.tournament = tournament
                
                // Použití RealmManager pro uložení turnaje
                if let realm = RealmManager.shared.realm {
                    try? realm.write {
                        realm.add(riposeMatch)
                    }
                }
            }
            
        }
        let lastTeam = players.removeLast()
        players.insert(lastTeam, at: 1)
    }
    
    
    return matches
}


func generateElimination(players: [Player], tournament: Tournament) -> [Match] {
    var matches: [Match] = []
    var shuffledPlayers = players.shuffled()
    let numberOfMatches = shuffledPlayers.count / 2
    
    for i in 0..<numberOfMatches {
        let player1 = shuffledPlayers[i * 2]
        let player2 = shuffledPlayers[i * 2 + 1]
        
        // Vytvoření zápasu
        let match = Match()
        match.player1 = player1
        match.player2 = player2
        match.fixturesRound = 1  
        match.tournament = tournament
        
        // Použití RealmManager pro uložení turnaje
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                realm.add(match)
            }
        }
        
        matches.append(match)
    }
    
    return matches
}

