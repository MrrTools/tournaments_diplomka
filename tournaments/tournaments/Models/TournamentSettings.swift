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
    @Persisted var winPoints: Int = 3
    @Persisted var losePoints: Int = 0
    @Persisted var drawPoints: Int = 1
    @Persisted var tournament: Tournament?
    
    convenience init(winPoints: Int = 3, losePoints: Int = 0, drawPoints: Int = 1, tournament: Tournament?) {
            self.init()
            self.winPoints = winPoints
            self.losePoints = losePoints
            self.drawPoints = drawPoints
            self.tournament = tournament
        }
}
