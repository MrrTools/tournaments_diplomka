//
//  Match.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//

import Foundation
import RealmSwift

class Match: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var player1: Player?
    @Persisted var player2: Player?
    @Persisted var player1Score: Int = 0
    @Persisted var player2Score: Int = 0
    @Persisted var fixturesRound: Int = 0
    @Persisted var matchDate: Date = Date()
    @Persisted var tournament: Tournament?

    convenience init(player1: Player?, player2: Player?, player1Score: Int = 0, player2Score: Int = 0, fixturesRound: Int = 0, matchDate: Date = Date(), tournament: Tournament?) {
        self.init()
        self.player1 = player1
        self.player2 = player2
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.matchDate = matchDate
        self.fixturesRound = fixturesRound
        self.tournament = tournament
    }}

