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
    @Published var selectedGroupIndex: Int = 0
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
    
    var isGroupStageAndKO: Bool {
        tournament.type == "Group Stage and KO"
    }
    
    var rounds: [[Match]] {
        var rounds: [[Match]] = []
        print("Number of Rounds: \(numberOfRounds)")
        for round in 1...numberOfRounds {
            if isGroupStageAndKO {
                let matchesInRound = matches.filter { $0.fixturesRound == round &&
                    $0.matchIndex == (selectedGroupIndex + 1)
                }
                rounds.append(matchesInRound)
            }
            else {
                let matchesInRound = matches.filter { $0.fixturesRound == round}
                rounds.append(matchesInRound)
            }
        }
        return rounds
    }
    
    
    var matchesForSelectedRound: [Match] {
        rounds[selectedRound - 1]
    }
    
    var numberOfRounds: Int {
        return matches.map { $0.fixturesRound }.max() ?? 0
    }
    
    var EliminationRounds: Int {
        return Int(log2(Double(numberOfPlayers)))
    }
    
    var numberOfPlayers: Int {
        return numberOfFixtures * 2
    }
    
    //$0 swift uzaver aktualna hodnota v poli
    var numberOfFixtures: Int {
        return matches.filter { $0.fixturesRound == 1 && $0.tournament == tournament }.count
    }
    
    //bitovy posun pre pocet kol pole napr 16 teamov [8,4,2,1]
    var matchesInSection: [Int] {
        (0..<EliminationRounds).map { round in
            numberOfPlayers >> (round + 1)
        }
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
    
    func updateMatchScore(match: Match, player1Score: Int, player2Score: Int, setsString: String, rematchFlag: Int) {
        if let realm = RealmManager.shared.realm {
            try? realm.write {
                if rematchFlag == 1 {
                    match.player1ScoreRematch = player1Score
                    match.player2ScoreRematch = player2Score
                } else {
                    match.player1Score = player1Score
                    match.player2Score = player2Score
                }
                
                
                match.setsString   = setsString
                
                realm.add(match, update: .modified)
            }
            updateTable(for: match, player1Score: player1Score, player2Score: player2Score)
            loadMatches()
            loadTable()
            objectWillChange.send()
        }
        
        if let tournament = match.tournament {
            if tournament.type == "Single Elimination" {
                var winner: Player?
                if player1Score > player2Score {
                    winner = match.player1
                } else if player2Score > player1Score {
                    winner = match.player2
                }
                
                guard let actualWinner = winner else { return }
                
                addWinnerToNextRound(winner: actualWinner, match: match)
            } else if tournament.type == "Double Elimination" {
                
                let firstMatchCompleted = match.player1Score != 0 || match.player2Score != 0
                let rematchCompleted = match.player1ScoreRematch != 0 || match.player2ScoreRematch != 0
                if firstMatchCompleted && rematchCompleted {
                    var winner: Player?
                    if match.player1Score + match.player1ScoreRematch  > match.player2Score + match.player2ScoreRematch {
                        winner = match.player1
                    } else if match.player2Score + match.player2ScoreRematch > match.player1Score + match.player1ScoreRematch {
                        winner = match.player2
                    }
                    guard let actualWinner = winner else { return }
                    addWinnerToNextRound(winner: actualWinner, match: match)
                }
                
            }
        }
    }
    
    func addWinnerToNextRound(winner: Player, match: Match) {
        let nextRound = match.fixturesRound + 1
        let nextMatchIndex = Int(floor(Double(match.matchIndex + 1) / 2)) + numberOfFixtures
        print("Found existing match with index \(nextMatchIndex) in round \(nextRound)")
        
        guard let realm = RealmManager.shared.realm else { return }
        
        if let nextMatch = realm.objects(Match.self).filter("matchIndex == %@ AND fixturesRound == %@ AND tournament == %@", nextMatchIndex, nextRound, match.tournament!).first {
            print("Found existing match with matchIndex \(nextMatchIndex) in round \(nextRound)")
            try? realm.write {
                if nextMatch.player1 == nil {
                    nextMatch.player1 = winner
                } else if nextMatch.player2 == nil {
                    nextMatch.player2 = winner
                }
                realm.add(nextMatch, update: .modified)
            }
        } else {
            let newMatch = Match()
            newMatch.fixturesRound = nextRound
            newMatch.matchIndex = nextMatchIndex
            newMatch.tournament = match.tournament
            
            try? realm.write {
                newMatch.player1 = winner
                realm.add(newMatch)
            }
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
                            player1Table.points += settings.winPoints
                            player2Table.points += settings.losePoints
                            player2Table.losses += 1
                        } else if player1Score < player2Score {
                            player2Table.wins += 1
                            player2Table.points += settings.winPoints
                            player1Table.points += settings.losePoints
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
        players.append(Player(name: "BYE", team: ""))
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
    let shuffledPlayers = players.shuffled()
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
        match.matchIndex = i + 1
        
        switch tournament.type {
        case "Double Elimination":
            match.rematchFlag = 1
        case "Playoff":
            match.plafOFFMatchCount = 1
        default:
            break  // Žiadna špeciálna akcia pre iné typy turnajov
        }
        
        
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

func generateGSKO(players: [Player],numberOfGroups: Int, advancingPerGroup: Int,tournament: Tournament, groupMatchesCount: Int) -> [Match] {
    // Ak hráčov náhodne premiešame, každá skupina bude inak poskladaná
    let allPlayers = players.shuffled()
    
    // 1. Rozdelenie hráčov do skupín
    var groups: [[Player]] = Array(repeating: [], count: numberOfGroups)
    for (i, player) in allPlayers.enumerated() {
        groups[i % numberOfGroups].append(player)
    }
    
    // 2. Vygenerovanie Round Robin zápasov pre každú skupinu
    var groupMatches: [Match] = []
    for (groupIndex, originalGroupPlayers) in groups.enumerated() {
        // Skopírujeme hráčov danej skupiny, prípadne pridáme "BYE" pri nepárnom počte
        var groupPlayers = originalGroupPlayers
        if groupPlayers.count % 2 != 0 {
            groupPlayers.append(Player(name: "BYE", team: ""))
        }
        let groupCount = groupPlayers.count
        
        // Round Robin logika: i od 1 do groupCount-1
        // (ak je BYE, tak bude aj tak jeden hráč vždy stáť)
        for round in 1..<(groupCount) {
            for j in 0..<(groupCount / 2) {
                let homeIndex = j
                let awayIndex = groupCount - 1 - j
                let homeTeam = groupPlayers[homeIndex]
                let awayTeam = groupPlayers[awayIndex]
                
                let match = Match()
                match.player1 = homeTeam
                match.player2 = awayTeam
                
                // matchIndex = číslo skupiny (1-based)
                match.matchIndex = groupIndex + 1
                // fixturesRound = kolo v rámci tejto skupiny
                match.fixturesRound = round
                match.tournament = tournament
                
                groupMatches.append(match)
                
                // Uloženie zápasu do Realm
                if let realm = RealmManager.shared.realm {
                    try? realm.write {
                        realm.add(match)
                    }
                }
            }
            // Implementujeme tzv. "circle shift" - posunieme posledného hráča dopredu
            // aby sme zachovali Round Robin
            let last = groupPlayers.removeLast()
            groupPlayers.insert(last, at: 1)
        }
    }
    
    // 3. Vygenerovanie skupinových tabuliek
    var groupTables: [TournamentTable] = []
    for group in groups {
        // Skupina mohla mať BYE, do tabulky to nepridávame
        let tables = group.filter { $0.name != "BYE" }
            .map { TournamentTable(player: $0, tournament: tournament) }
        groupTables.append(contentsOf: tables)
    }
    
    // 4. Uloženie skupinových zápasov a tabuliek do turnaja
    if let realm = RealmManager.shared.realm {
        try? realm.write {
            tournament.matches.append(objectsIn: groupMatches)
            tournament.table.append(objectsIn: groupTables)
            realm.add(tournament, update: .modified)
        }
    }
    
    
    return groupMatches
}


