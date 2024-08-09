//
//  Tournaments.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import Foundation
import RealmSwift

class Player: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String = ""
    @Persisted var photoData: Data? // To store photo
    
    convenience init(name: String, photoData: Data? = nil) {
        self.init()
        self.name = name
        self.photoData = photoData
    }
}

class Tournament: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String = ""
    @Persisted var owner: String = ""
    @Persisted var sport: String = ""
    @Persisted var type: String = ""
    @Persisted var players: List<Player>
    @Persisted var matches: List<Match>
    @Persisted var table: List<TournamentTable>
    
    convenience init(name: String, owner: String, sport: String, type: String, players: [Player], matches: [Match], table: [TournamentTable]) {
        self.init()
        self.name = name
        self.owner = owner
        self.sport = sport
        self.type = type
        self.players.append(objectsIn: players)
        self.matches.append(objectsIn: matches)
        self.table.append(objectsIn: table)
    }
}


