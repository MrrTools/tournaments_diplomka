//
//  F1Race.swift
//  tournaments
//
//  Created by Lukas Sarocky on 21.02.2025.
//

import Foundation
import RealmSwift

class F1Race: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var country: String
    @Persisted var laps: Int
    @Persisted var date: Date
    @Persisted var player: Player?
    @Persisted var position: Int?
    @Persisted var startPosition: Int
    @Persisted var fastestLap: String
    @Persisted var pitStops: Int
    @Persisted var finished: String
    @Persisted var raceNumber: Int = 0
    @Persisted var tournament: Tournament?
    
    convenience init(name: String, country: String, laps: Int, date: Date, player: Player?, position: Int?, startPosition: Int, fastestLap: String, pitStops: Int, finished: String, raceNumber: Int = 0, tournament: Tournament?) {
        self.init()
        self.name = name
        self.country = country
        self.laps = laps
        self.date = date
        self.player = player
        self.position = position
        self.startPosition = startPosition
        self.fastestLap = fastestLap
        self.pitStops = pitStops
        self.finished = finished
        self.raceNumber = raceNumber
        self.tournament = tournament
    }
}
