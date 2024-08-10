//
//  TournamentSettings.swift
//  tournaments
//
//  Created by Lukas Sarocky on 10.08.2024.
//

import Foundation
import RealmSwift

class TournamentSettings: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var winScore: Int = 3
    @Persisted var loseScore: Int = 0
    @Persisted var drawScore: Int = 1
    @Persisted var tournament: Tournament?
    
    convenience init(winScore: Int = 3, loseScore: Int = 0, drawScore: Int = 1, tournament: Tournament?) {
            self.init()
            self.winScore = winScore
            self.loseScore = loseScore
            self.drawScore = loseScore
            self.tournament = tournament
        }
}
