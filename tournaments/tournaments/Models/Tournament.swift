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
    @Persisted var numberOfAdvancePlayers: Int?
    @Persisted var numberOfGroups: Int?
    @Persisted var playOFFMatches: Int?
    @Persisted var qualifiedToNextRound: Int?
    @Persisted var numberOfRaces: Int?
    @Persisted var riposeFinal: Bool?
    @Persisted var riposeKnockOut: Bool?
    @Persisted var riposeMatches: Bool?
    @Persisted var players: List<Player>
    @Persisted var matches: List<TournamentMatch>
    @Persisted var table: List<TournamentTable>
    @Persisted var settings: List<TournamentSettings>
    @Persisted var f1Race: List<F1Race>
    @Persisted var f1TeamTable: List<F1TeamTable>
    @Persisted var f1PlayerTable: List<F1PlayerTable>
    
    
    convenience init(name: String, owner: String, sport: String, type: String, groupNumber: Int?, numberOfAdvancePlayers: Int?, numberOfGroups: Int?, playOFFMatches: Int?, qualifiedToNextRound: Int?, riposeFinal: Bool?, riposeKnockOut: Bool?, riposeMatches: Bool?, numberOfRaces: Int?, players: [Player], matches: [TournamentMatch], table: [TournamentTable], settings: [TournamentSettings], f1Race: [F1Race], f1TeamTable: [F1TeamTable], f1PlayerTable: [F1PlayerTable]) {
        self.init()
        self.name = name
        self.owner = owner
        self.sport = sport
        self.type = type
        self.groupNumber = groupNumber
        self.numberOfAdvancePlayers = numberOfAdvancePlayers
        self.numberOfGroups = numberOfGroups
        self.playOFFMatches = playOFFMatches
        self.qualifiedToNextRound = qualifiedToNextRound
        self.numberOfRaces = numberOfRaces
        self.riposeFinal = riposeFinal
        self.riposeKnockOut = riposeKnockOut
        self.riposeMatches = riposeMatches
        self.players.append(objectsIn: players)
        self.matches.append(objectsIn: matches)
        self.table.append(objectsIn: table)
        self.settings.append(objectsIn: settings)
        self.f1Race.append(objectsIn: f1Race)
        self.f1TeamTable.append(objectsIn: f1TeamTable)
        self.f1PlayerTable.append(objectsIn: f1PlayerTable)
    }
}


