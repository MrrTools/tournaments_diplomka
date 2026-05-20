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
    @Published var matches: [TournamentMatch] = []
    @Published var selectedRound: Int = 1 {
        didSet {
            loadMatches()
            loadTable()
        }
    }
    
    @Published var selectedGroupIndex: Int = 0 {
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
    
    var rounds: [[TournamentMatch]] {
        var rounds: [[TournamentMatch]] = []
        for round in 1...numberOfRounds {
            if isGroupStageAndKO {
                let matchesInRound = matches.filter { $0.fixturesRound == round &&
                    $0.groupIndex == (selectedGroupIndex + 1)
                }
                rounds.append(matchesInRound)
            }
            else {
                let matchesInRound = matches.filter { $0.fixturesRound == round}
                rounds.append(matchesInRound)
            }
        }
        print("GroupIndex: \(selectedGroupIndex + 1)")
        return rounds
    }
    
    
    var matchesForSelectedRound: [TournamentMatch] {
        rounds[selectedRound - 1]
    }
    
    var numberOfRounds: Int {
        return matches.map { $0.fixturesRound }.max() ?? 0
    }
    
    var EliminationRounds: Int {
        guard numberOfPlayers > 0 else { return 0 }
        return Int(log2(Double(numberOfPlayers)))
    }
    
    var numberOfPlayers: Int {
        return numberOfFixtures * 2
    }
    
    //$0 swift uzaver aktualna hodnota v poli
    var numberOfFixtures: Int {
        if tournament.type == "Group Stage and KO" {
            // Pre GSKO: najprv skús nájsť KO zápasy
            let koMatches = matches.filter { $0.fixturesRound == 1 && $0.tournament == tournament && $0.groupIndex == 0 }.count

            // Ak KO zápasy existujú, použi ich počet
            if koMatches > 0 {
                return koMatches
            }

            // Ak ešte neexistujú KO zápasy, vypočítaj z postupujúcich hráčov
            let numberOfGroups = tournament.numberOfGroups ?? 4
            let advancingPerGroup = tournament.numberOfAdvancePlayers ?? 2
            let totalAdvancing = numberOfGroups * advancingPerGroup
            return totalAdvancing / 2
        }

        // Pre iné typy turnajov
        return matches.filter { $0.fixturesRound == 1 && $0.tournament == tournament }.count
    }
    
    //bitovy posun pre pocet kol pole napr 16 teamov [8,4,2,1]
    var matchesInSection: [Int] {
        (0..<EliminationRounds).map { round in
            numberOfPlayers >> (round + 1)
        }
    }
    
    func loadMatches() {
        let matches = realm.objects(TournamentMatch.self).filter("tournament == %@", tournament)
        self.matches = Array(matches)
        objectWillChange.send()
    }
    
    func loadTable() {
        let table = realm.objects(TournamentTable.self).filter("tournament == %@", tournament)
        self.table = Array(table)
        objectWillChange.send()
    }
    
    func updateMatchScore(match: TournamentMatch, player1Score: Int, player2Score: Int, setsString: String, rematchFlag: Int, koFlag: Bool) {
        if let realm = RealmManager.shared.realm {
            
            // Kontrola, či bol prvý zápas už vyhodnotený
            if match.isPlayed {
                updateTable(for: match, player1Score: match.player1Score, player2Score: match.player2Score, remove: true)
            }
            
            // Kontrola, či bola odveta už vyhodnotená
            if match.isRematchPlayed {
                updateTable(for: match, player1Score: match.player1ScoreRematch, player2Score: match.player2ScoreRematch, remove: true)
            }

            RealmManager.safeWrite(realm, operation: "updateMatchScore") {

                if rematchFlag == 1 {
                    match.player1ScoreRematch = player1Score
                    match.player2ScoreRematch = player2Score
                    match.isRematchPlayed = true
                } else {
                    match.player1Score = player1Score
                    match.player2Score = player2Score
                    match.isPlayed = true
                }


                match.setsString   = setsString

                realm.add(match, update: .modified)
            }

            updateTable(for: match, player1Score: player1Score, player2Score: player2Score, remove: false)
            loadMatches()
            loadTable()
            objectWillChange.send()
        }
        
        var playOffLegDone: Bool {
            let threshold = ((tournament.playOFFMatches ?? 0) / 2) + 1
            return threshold == player1Score || threshold == player2Score
        }
        
        
        if let tournament = match.tournament {
            let isFinalMatch = match.fixturesRound ==  EliminationRounds

            // Single Elimination - vždy postupuje víťaz
            if tournament.type == "Single Elimination" {
                var winner: Player?
                if player1Score > player2Score {
                    winner = match.player1
                } else if player2Score > player1Score {
                    winner = match.player2
                }

                guard let actualWinner = winner else { return }
                addWinnerToNextRound(winner: actualWinner, match: match)
            }
            // Group Stage and KO - postupuje víťaz len v KO fáze
            else if tournament.type == "Group Stage and KO" && !koFlag {
                if (tournament.riposeKnockOut == false && tournament.riposeFinal == false) ||
                   (tournament.riposeFinal == true && isFinalMatch) {
                    var winner: Player?
                    if player1Score > player2Score {
                        winner = match.player1
                    } else if player2Score > player1Score {
                        winner = match.player2
                    }

                    guard let actualWinner = winner else { return }
                    addWinnerToNextRound(winner: actualWinner, match: match)
                }
            }
            // Playoff - postupuje víťaz po dokončení série
            else if tournament.type == "Playoff" && playOffLegDone {
                var winner: Player?
                if player1Score > player2Score {
                    winner = match.player1
                } else if player2Score > player1Score {
                    winner = match.player2
                }

                guard let actualWinner = winner else { return }
                addWinnerToNextRound(winner: actualWinner, match: match)
            } else if tournament.type == "Double Elimination" ||
                        (tournament.type == "Group Stage and KO" &&
                         ((tournament.riposeKnockOut == true && tournament.riposeFinal == true) ||
                          (tournament.riposeFinal == true && isFinalMatch))){
                
                // Kontrola, či sú oba zápasy dokončené pomocou flagov
                if match.isPlayed && match.isRematchPlayed {
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
    
    func addWinnerToNextRound(winner: Player, match: TournamentMatch) {
        let nextRound = match.fixturesRound + 1
        let nextMatchIndex = Int(floor(Double(match.matchIndex + 1) / 2)) + numberOfFixtures
        print("Found existing match with index \(nextMatchIndex) in round \(nextRound)")
        
        guard let realm = RealmManager.shared.realm else { return }
        
        if let nextMatch = realm.objects(TournamentMatch.self).filter("matchIndex == %@ AND fixturesRound == %@ AND tournament == %@", nextMatchIndex, nextRound, match.tournament!).first {
            print("Found existing match with matchIndex \(nextMatchIndex) in round \(nextRound)")
            RealmManager.safeWrite(realm, operation: "addWinnerToNextRound-update") {
                // Kontrola, či sa víťaz zmenil a potrebujeme ho aktualizovať
                if nextMatch.player1 == match.player1 || nextMatch.player1 == match.player2 {
                    nextMatch.player1 = winner
                } else if nextMatch.player2 == match.player1 || nextMatch.player2 == match.player2 {
                    nextMatch.player2 = winner
                } else {
                    // Ak ešte nie je pridelený druhý hráč, pridáme ho na správne miesto
                    if nextMatch.player1 == nil {
                        nextMatch.player1 = winner
                    } else if nextMatch.player2 == nil {
                        nextMatch.player2 = winner
                    }
                }
                realm.add(nextMatch, update: .modified)
            }
        } else {
            let newMatch = TournamentMatch()
            newMatch.fixturesRound = nextRound
            newMatch.matchIndex = nextMatchIndex
            newMatch.tournament = match.tournament

            RealmManager.safeWrite(realm, operation: "addWinnerToNextRound-create") {
                newMatch.player1 = winner
                realm.add(newMatch)
                match.tournament?.matches.append(newMatch)
            }

            loadMatches()
            objectWillChange.send()
        }
    }
    
    
    
    
    func updateTable(for match: TournamentMatch, player1Score: Int, player2Score: Int, remove: Bool) {
        guard let settings = tournament.settings.first else {
            print("Tournament settings not found")
            return
        }
        
        let player1 = match.player1!
        let player2 = match.player2!
        
        if let player1Table = tournament.table.first(where: { $0.player == player1 }) {
            if let player2Table = tournament.table.first(where: { $0.player == player2 }) {
                if let realm = RealmManager.shared.realm {
                    RealmManager.safeWrite(realm, operation: "updateTable") {
                        let refreshScore = remove ? -1 : 1
                        
                        if player1Score > player2Score {
                            player1Table.wins += 1 * refreshScore
                            player1Table.points += settings.winPoints * refreshScore
                            player2Table.points += settings.losePoints * refreshScore
                            player2Table.losses += 1 * refreshScore
                        } else if player1Score < player2Score {
                            player2Table.wins += 1 * refreshScore
                            player2Table.points += settings.winPoints * refreshScore
                            player1Table.points += settings.losePoints * refreshScore
                            player1Table.losses += 1 * refreshScore
                        } else {
                            player1Table.draws += 1 * refreshScore
                            player2Table.draws += 1 * refreshScore
                            player1Table.points += settings.drawPoints * refreshScore
                            player2Table.points += settings.drawPoints * refreshScore
                        }
                        player1Table.goalsScored += player1Score * refreshScore
                        player1Table.goalsConceded += player2Score * refreshScore
                        player2Table.goalsScored += player2Score * refreshScore
                        player2Table.goalsConceded += player1Score * refreshScore
                        
                        print("Found existing match with index \(player1Table.goalsScored) in round \(player1Table.goalsConceded )")
                        print("Found existing match with index \(player2Table.goalsScored) in round \(player2Table.goalsConceded )")
                        realm.add(player1Table, update: .modified)
                        realm.add(player2Table, update: .modified)
                    }
                }
            }
        }
    }
}

//Generovanie Round Robin
func generateRoundRobinMatches(players: [Player], tournament: Tournament, riposeMatches: Bool) -> [TournamentMatch] {
    var matches: [TournamentMatch] = []
    var players = players
    
    // Ak je nepárny počet hráčov, pridáme "BYE" hráča
    if players.count % 2 != 0 {
        players.append(Player(name: "BYE", team: ""))
    }
    
    for i in 1..<players.count {
        for j in 0..<players.count / 2 {
            let homeTeam = players[j]
            let awayTeam = players[players.count - 1 - j]
            
            // Preskočíme zápasy s "BYE" tímom
            if homeTeam.name == "BYE" || awayTeam.name == "BYE" {
                continue
            }
            
            let match = TournamentMatch()
            match.player1 = homeTeam
            match.player2 = awayTeam
            match.fixturesRound = i
            match.tournament = tournament
            matches.append(match)
            
            // Odveta (ak je povolená)
            if riposeMatches {
                let riposeMatch = TournamentMatch()
                riposeMatch.player1 = awayTeam
                riposeMatch.player2 = homeTeam
                riposeMatch.fixturesRound = players.count - 1 + i
                riposeMatch.tournament = tournament
                matches.append(riposeMatch)
            }
        }
        
        // Rotácia tímov pre ďalšie kolo
        let lastTeam = players.removeLast()
        players.insert(lastTeam, at: 1)
    }

    return matches
}



func generateElimination(players: [Player], tournament: Tournament) -> [TournamentMatch] {
    var matches: [TournamentMatch] = []
    let shuffledPlayers = players.shuffled()
    let numberOfMatches = shuffledPlayers.count / 2
    
    for i in 0..<numberOfMatches {
        let player1 = shuffledPlayers[i * 2]
        let player2 = shuffledPlayers[i * 2 + 1]
        
        // Vytvoření zápasu
        let match = TournamentMatch()
        match.player1 = player1
        match.player2 = player2
        match.fixturesRound = 1
        match.tournament = tournament
        match.matchIndex = i + 1
        
        switch tournament.type {
        case "Double Elimination":
            match.rematchFlag = 1
        default:
            break  // Žiadna špeciálna akcia pre iné typy turnajov
        }

        matches.append(match)
    }

    return matches
}

func generateGSKO(players: [Player], numberOfPlayersInGroup: Int, advancingPerGroup: Int, tournament: Tournament, riposeMatches: Bool) -> ([TournamentMatch], [TournamentTable]) {
    // Ak hráčov náhodne premiešame, každá skupina bude inak poskladaná
    let allPlayers = players.shuffled()
    let numberOfGroups = allPlayers.count / numberOfPlayersInGroup
    
    // 1. Rozdelenie hráčov do skupín
    var groups: [[Player]] = Array(repeating: [], count: numberOfGroups)
    for (i, player) in allPlayers.enumerated() {
        groups[i % numberOfGroups].append(player)
    }
    
    // 2. Vygenerovanie Round Robin zápasov pre každú skupinu
    var groupMatches: [TournamentMatch] = []
    var groupTables: [TournamentTable] = [] // Tabuľky pre všetky skupiny
    
    for (groupIndex, originalGroupPlayers) in groups.enumerated() {
        // Skopírujeme hráčov danej skupiny, prípadne pridáme "BYE" pri nepárnom počte
        var groupPlayers = originalGroupPlayers
        if groupPlayers.count % 2 != 0 {
            groupPlayers.append(Player(name: "BYE", team: ""))
        }
        let groupCount = groupPlayers.count
        
        // Round Robin logika: i od 1 do groupCount-1
        for round in 1..<(groupCount) {
            for j in 0..<(groupCount / 2) {
                let homeIndex = j
                let awayIndex = groupCount - 1 - j
                let homeTeam = groupPlayers[homeIndex]
                let awayTeam = groupPlayers[awayIndex]
                
                let match = TournamentMatch()
                match.player1 = homeTeam
                match.player2 = awayTeam
                match.groupIndex = groupIndex + 1
                match.fixturesRound = round
                match.tournament = tournament

                groupMatches.append(match)

                // Odvety
                if riposeMatches {
                    let riposeMatch = TournamentMatch()
                    riposeMatch.player1 = awayTeam
                    riposeMatch.player2 = homeTeam
                    riposeMatch.fixturesRound = groupCount - 1 + round
                    riposeMatch.tournament = tournament
                    riposeMatch.groupIndex = groupIndex + 1

                    groupMatches.append(riposeMatch)
                }
            }
            
            // Implementujeme tzv. "circle shift" - posunieme posledného hráča dopredu
            let last = groupPlayers.removeLast()
            groupPlayers.insert(last, at: 1)
        }
        
        // 3. Vytvorenie tabuľky pre danú skupinu
        let tables = groupPlayers
            .filter { $0.name != "BYE" }
            .map { player in
                let table = TournamentTable(player: player, tournament: tournament)
                table.groupIndex = groupIndex + 1
                return table
            }
        
        groupTables.append(contentsOf: tables)
    }

    return (groupMatches, groupTables)
}



