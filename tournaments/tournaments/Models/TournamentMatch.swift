//
//  Match.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//

//definition
//@Persisted data for storage in Realm



import Foundation
import RealmSwift

class TournamentMatch: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var player1: Player?
    @Persisted var player2: Player?
    @Persisted var player1Score: Int = 0
    @Persisted var player2Score: Int = 0
    @Persisted var player1ScoreRematch: Int = 0
    @Persisted var player2ScoreRematch: Int = 0
    @Persisted var setsString: String?
    @Persisted var fixturesRound: Int = 0
    @Persisted var matchDate: Date = Date()
    @Persisted var tournament: Tournament?
    @Persisted var matchIndex: Int = 0
    @Persisted var groupIndex: Int = 0
    @Persisted var rematchFlag: Int = 0
    @Persisted var plafOFFMatchCount: Int = 0
    
    
    convenience init(player1: Player?, player2: Player?, player1Score: Int = 0, player2Score: Int = 0, setsString: String?, fixturesRound: Int = 0, matchDate: Date = Date(), tournament: Tournament?, matchIndex: Int = 0, rematchFlag: Int = 0, player1ScoreRematch: Int = 0, player2ScoreRematch: Int = 0, plafOFFMatchCount: Int = 0, groupIndex: Int = 0) {
        self.init()
        self.player1 = player1
        self.player2 = player2
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.setsString = setsString
        self.matchDate = matchDate
        self.fixturesRound = fixturesRound
        self.tournament = tournament
        self.matchIndex = matchIndex
        self.rematchFlag = rematchFlag
        self.player1ScoreRematch = player1ScoreRematch
        self.player2ScoreRematch = player2ScoreRematch
        self.plafOFFMatchCount = plafOFFMatchCount
        self.groupIndex = groupIndex
        
    }}

