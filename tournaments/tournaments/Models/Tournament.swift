//
//  Tournaments.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import Foundation
import RealmSwift

class Tournament: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String = ""
    @Persisted var owner: String = ""
    @Persisted var sport: String = ""
    @Persisted var type: String = ""
    @Persisted var groupNumber: Int?
    @Persisted var playOFFMatches: Int?
    @Persisted var qualifiedToNextRound: Int?
    @Persisted var players: List<Player>
    @Persisted var matches: List<TournamentMatch>
    @Persisted var table: List<TournamentTable>
    @Persisted var settings: List<TournamentSettings>
    
    
    convenience init(name: String, owner: String, sport: String, type: String, groupNumber: Int?, playOFFMatches: Int?, qualifiedToNextRound: Int?, players: [Player], matches: [TournamentMatch], table: [TournamentTable], settings: [TournamentSettings]) {
        self.init()
        self.name = name
        self.owner = owner
        self.sport = sport
        self.type = type
        self.groupNumber = groupNumber
        self.playOFFMatches = playOFFMatches
        self.qualifiedToNextRound = qualifiedToNextRound
        self.players.append(objectsIn: players)
        self.matches.append(objectsIn: matches)
        self.table.append(objectsIn: table)
        self.settings.append(objectsIn: settings)
    }
}


