//
//  F1TeamTable.swift
//  tournaments
//
//  Created by Lukas Sarocky on 21.02.2025.
//

import Foundation
import RealmSwift

class F1TeamTable: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var teamName: String
    @Persisted var totalPoints: Int = 0
    @Persisted var wins: Int = 0
    @Persisted var fastestLaps: Int = 0
    @Persisted var podiums: Int = 0
    @Persisted var tournament: Tournament?

    convenience init(teamName: String, totalPoints: Int = 0, wins: Int = 0, fastestLaps: Int = 0, podiums: Int = 0, tournament: Tournament?) {
        self.init()
        self.teamName = teamName
        self.totalPoints = totalPoints
        self.wins = wins
        self.fastestLaps =  fastestLaps
        self.podiums = podiums
        self.tournament = tournament
    }
}
