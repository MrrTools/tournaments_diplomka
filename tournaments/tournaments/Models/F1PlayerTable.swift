//
//  F1PlayerTable.swift
//  tournaments
//
//  Created by Lukas Sarocky on 21.02.2025.
//

import Foundation
import RealmSwift

class F1PlayerTable: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var player: Player?
    @Persisted var totalPoints: Int = 0
    @Persisted var wins: Int = 0
    @Persisted var fastestLaps: Int = 0
    @Persisted var podiums: Int = 0
    @Persisted var tournament: Tournament?

    convenience init(player: Player?, totalPoints: Int = 0, wins: Int = 0, fastestLaps: Int = 0, podiums: Int = 0, tournament: Tournament?) {
        self.init()
        self.player = player
        self.totalPoints = totalPoints
        self.wins = wins
        self.fastestLaps =  fastestLaps
        self.podiums = podiums
        self.tournament = tournament
    }
}
