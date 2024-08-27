//
//  Table.swift
//  tournaments
//
//  Created by Lukas Sarocky on 16.07.2024.
//

import Foundation
import RealmSwift

class TournamentTable: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var player: Player?
    @Persisted var points: Int = 0
    @Persisted var goalsScored: Int = 0
    @Persisted var goalsConceded: Int = 0
    @Persisted var wins: Int = 0
    @Persisted var losses: Int = 0
    @Persisted var draws: Int = 0
    @Persisted var tournament: Tournament?
    
    convenience init(player: Player?, tournament: Tournament?) {
        self.init()
        self.player = player
        self.tournament = tournament
    }
    
    var scoreDifference: Int {
        return goalsScored - goalsConceded
    }
}


