//
//  PowerSyncModels.swift
//  tournaments
//
//  Created by PowerSync Migration
//  Swift structs representing PowerSync database entities
//

import Foundation

// MARK: - Player Model
struct PlayerModel: Codable, Identifiable {
    var id: String
    var name: String
    var team: String?
    var photoData: Data?

    init(id: String = UUID().uuidString, name: String, team: String? = nil, photoData: Data? = nil) {
        self.id = id
        self.name = name
        self.team = team
        self.photoData = photoData
    }

    // Convert to dictionary for PowerSync
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name
        ]
        if let team = team {
            dict["team"] = team
        }
        if let photoData = photoData {
            dict["photo_data"] = photoData.base64EncodedString()
        }
        return dict
    }

    // Create from database row
    static func from(row: [String: Any]) -> PlayerModel? {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String else {
            return nil
        }

        let team = row["team"] as? String
        var photoData: Data? = nil
        if let photoString = row["photo_data"] as? String {
            photoData = Data(base64Encoded: photoString)
        }

        return PlayerModel(id: id, name: name, team: team, photoData: photoData)
    }
}

// MARK: - Tournament Model
struct TournamentModel: Codable, Identifiable {
    var id: String
    var name: String
    var owner: String
    var sport: String
    var type: String
    var groupNumber: Int?
    var numberOfAdvancePlayers: Int?
    var numberOfGroups: Int?
    var playoffMatches: Int?
    var numberOfRaces: Int?
    var riposeFinal: Bool?
    var riposeKnockout: Bool?
    var riposeMatches: Bool?
    var email: String?
    var createdDate: Date

    init(id: String = UUID().uuidString,
         name: String,
         owner: String,
         sport: String,
         type: String,
         groupNumber: Int? = nil,
         numberOfAdvancePlayers: Int? = nil,
         numberOfGroups: Int? = nil,
         playoffMatches: Int? = nil,
         numberOfRaces: Int? = nil,
         riposeFinal: Bool? = nil,
         riposeKnockout: Bool? = nil,
         riposeMatches: Bool? = nil,
         email: String? = nil,
         createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.owner = owner
        self.sport = sport
        self.type = type
        self.groupNumber = groupNumber
        self.numberOfAdvancePlayers = numberOfAdvancePlayers
        self.numberOfGroups = numberOfGroups
        self.playoffMatches = playoffMatches
        self.numberOfRaces = numberOfRaces
        self.riposeFinal = riposeFinal
        self.riposeKnockout = riposeKnockout
        self.riposeMatches = riposeMatches
        self.email = email
        self.createdDate = createdDate
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "owner": owner,
            "sport": sport,
            "type": type,
            "created_date": Int(createdDate.timeIntervalSince1970)
        ]

        if let groupNumber = groupNumber { dict["group_number"] = groupNumber }
        if let numberOfAdvancePlayers = numberOfAdvancePlayers { dict["number_of_advance_players"] = numberOfAdvancePlayers }
        if let numberOfGroups = numberOfGroups { dict["number_of_groups"] = numberOfGroups }
        if let playoffMatches = playoffMatches { dict["playoff_matches"] = playoffMatches }
        if let numberOfRaces = numberOfRaces { dict["number_of_races"] = numberOfRaces }
        if let riposeFinal = riposeFinal { dict["ripose_final"] = riposeFinal ? 1 : 0 }
        if let riposeKnockout = riposeKnockout { dict["ripose_knockout"] = riposeKnockout ? 1 : 0 }
        if let riposeMatches = riposeMatches { dict["ripose_matches"] = riposeMatches ? 1 : 0 }
        if let email = email { dict["email"] = email }

        return dict
    }

    static func from(row: [String: Any]) -> TournamentModel? {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String,
              let owner = row["owner"] as? String,
              let sport = row["sport"] as? String,
              let type = row["type"] as? String,
              let createdTimestamp = row["created_date"] as? Int else {
            return nil
        }

        return TournamentModel(
            id: id,
            name: name,
            owner: owner,
            sport: sport,
            type: type,
            groupNumber: row["group_number"] as? Int,
            numberOfAdvancePlayers: row["number_of_advance_players"] as? Int,
            numberOfGroups: row["number_of_groups"] as? Int,
            playoffMatches: row["playoff_matches"] as? Int,
            numberOfRaces: row["number_of_races"] as? Int,
            riposeFinal: (row["ripose_final"] as? Int) == 1,
            riposeKnockout: (row["ripose_knockout"] as? Int) == 1,
            riposeMatches: (row["ripose_matches"] as? Int) == 1,
            email: row["email"] as? String,
            createdDate: Date(timeIntervalSince1970: TimeInterval(createdTimestamp))
        )
    }
}

// MARK: - Tournament Match Model
struct TournamentMatchModel: Codable, Identifiable {
    var id: String
    var tournamentId: String
    var player1Id: String?
    var player2Id: String?
    var player1Score: Int
    var player2Score: Int
    var player1ScoreRematch: Int
    var player2ScoreRematch: Int
    var setsString: String?
    var fixturesRound: Int
    var matchDate: Date
    var matchIndex: Int
    var groupIndex: Int
    var rematchFlag: Int

    init(id: String = UUID().uuidString,
         tournamentId: String,
         player1Id: String? = nil,
         player2Id: String? = nil,
         player1Score: Int = 0,
         player2Score: Int = 0,
         player1ScoreRematch: Int = 0,
         player2ScoreRematch: Int = 0,
         setsString: String? = nil,
         fixturesRound: Int = 0,
         matchDate: Date = Date(),
         matchIndex: Int = 0,
         groupIndex: Int = 0,
         rematchFlag: Int = 0) {
        self.id = id
        self.tournamentId = tournamentId
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.player1ScoreRematch = player1ScoreRematch
        self.player2ScoreRematch = player2ScoreRematch
        self.setsString = setsString
        self.fixturesRound = fixturesRound
        self.matchDate = matchDate
        self.matchIndex = matchIndex
        self.groupIndex = groupIndex
        self.rematchFlag = rematchFlag
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "tournament_id": tournamentId,
            "player1_score": player1Score,
            "player2_score": player2Score,
            "player1_score_rematch": player1ScoreRematch,
            "player2_score_rematch": player2ScoreRematch,
            "fixtures_round": fixturesRound,
            "match_date": Int(matchDate.timeIntervalSince1970),
            "match_index": matchIndex,
            "group_index": groupIndex,
            "rematch_flag": rematchFlag
        ]

        if let player1Id = player1Id { dict["player1_id"] = player1Id }
        if let player2Id = player2Id { dict["player2_id"] = player2Id }
        if let setsString = setsString { dict["sets_string"] = setsString }

        return dict
    }

    static func from(row: [String: Any]) -> TournamentMatchModel? {
        guard let id = row["id"] as? String,
              let tournamentId = row["tournament_id"] as? String,
              let matchTimestamp = row["match_date"] as? Int else {
            return nil
        }

        return TournamentMatchModel(
            id: id,
            tournamentId: tournamentId,
            player1Id: row["player1_id"] as? String,
            player2Id: row["player2_id"] as? String,
            player1Score: row["player1_score"] as? Int ?? 0,
            player2Score: row["player2_score"] as? Int ?? 0,
            player1ScoreRematch: row["player1_score_rematch"] as? Int ?? 0,
            player2ScoreRematch: row["player2_score_rematch"] as? Int ?? 0,
            setsString: row["sets_string"] as? String,
            fixturesRound: row["fixtures_round"] as? Int ?? 0,
            matchDate: Date(timeIntervalSince1970: TimeInterval(matchTimestamp)),
            matchIndex: row["match_index"] as? Int ?? 0,
            groupIndex: row["group_index"] as? Int ?? 0,
            rematchFlag: row["rematch_flag"] as? Int ?? 0
        )
    }
}

// MARK: - Tournament Settings Model
struct TournamentSettingsModel: Codable, Identifiable {
    var id: String
    var tournamentId: String
    var winPoints: Int
    var losePoints: Int
    var drawPoints: Int

    init(id: String = UUID().uuidString,
         tournamentId: String,
         winPoints: Int = 3,
         losePoints: Int = 0,
         drawPoints: Int = 1) {
        self.id = id
        self.tournamentId = tournamentId
        self.winPoints = winPoints
        self.losePoints = losePoints
        self.drawPoints = drawPoints
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "tournament_id": tournamentId,
            "win_points": winPoints,
            "lose_points": losePoints,
            "draw_points": drawPoints
        ]
    }

    static func from(row: [String: Any]) -> TournamentSettingsModel? {
        guard let id = row["id"] as? String,
              let tournamentId = row["tournament_id"] as? String else {
            return nil
        }

        return TournamentSettingsModel(
            id: id,
            tournamentId: tournamentId,
            winPoints: row["win_points"] as? Int ?? 3,
            losePoints: row["lose_points"] as? Int ?? 0,
            drawPoints: row["draw_points"] as? Int ?? 1
        )
    }
}

// MARK: - Tournament Table Model
struct TournamentTableModel: Codable, Identifiable {
    var id: String
    var tournamentId: String
    var playerId: String
    var points: Int
    var goalsScored: Int
    var goalsConceded: Int
    var wins: Int
    var losses: Int
    var draws: Int
    var groupIndex: Int

    var scoreDifference: Int {
        return goalsScored - goalsConceded
    }

    init(id: String = UUID().uuidString,
         tournamentId: String,
         playerId: String,
         points: Int = 0,
         goalsScored: Int = 0,
         goalsConceded: Int = 0,
         wins: Int = 0,
         losses: Int = 0,
         draws: Int = 0,
         groupIndex: Int = 0) {
        self.id = id
        self.tournamentId = tournamentId
        self.playerId = playerId
        self.points = points
        self.goalsScored = goalsScored
        self.goalsConceded = goalsConceded
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.groupIndex = groupIndex
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "tournament_id": tournamentId,
            "player_id": playerId,
            "points": points,
            "goals_scored": goalsScored,
            "goals_conceded": goalsConceded,
            "wins": wins,
            "losses": losses,
            "draws": draws,
            "group_index": groupIndex
        ]
    }

    static func from(row: [String: Any]) -> TournamentTableModel? {
        guard let id = row["id"] as? String,
              let tournamentId = row["tournament_id"] as? String,
              let playerId = row["player_id"] as? String else {
            return nil
        }

        return TournamentTableModel(
            id: id,
            tournamentId: tournamentId,
            playerId: playerId,
            points: row["points"] as? Int ?? 0,
            goalsScored: row["goals_scored"] as? Int ?? 0,
            goalsConceded: row["goals_conceded"] as? Int ?? 0,
            wins: row["wins"] as? Int ?? 0,
            losses: row["losses"] as? Int ?? 0,
            draws: row["draws"] as? Int ?? 0,
            groupIndex: row["group_index"] as? Int ?? 0
        )
    }
}

// MARK: - F1 Race Model
struct F1RaceModel: Codable, Identifiable {
    var id: String
    var tournamentId: String
    var playerId: String?
    var name: String
    var country: String
    var laps: Int
    var date: Date
    var position: Int?
    var startPosition: Int
    var fastestLap: String
    var pitStops: Int
    var finished: String
    var raceNumber: Int

    init(id: String = UUID().uuidString,
         tournamentId: String,
         playerId: String? = nil,
         name: String,
         country: String,
         laps: Int,
         date: Date,
         position: Int? = nil,
         startPosition: Int,
         fastestLap: String,
         pitStops: Int,
         finished: String,
         raceNumber: Int = 0) {
        self.id = id
        self.tournamentId = tournamentId
        self.playerId = playerId
        self.name = name
        self.country = country
        self.laps = laps
        self.date = date
        self.position = position
        self.startPosition = startPosition
        self.fastestLap = fastestLap
        self.pitStops = pitStops
        self.finished = finished
        self.raceNumber = raceNumber
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "tournament_id": tournamentId,
            "name": name,
            "country": country,
            "laps": laps,
            "date": Int(date.timeIntervalSince1970),
            "start_position": startPosition,
            "fastest_lap": fastestLap,
            "pit_stops": pitStops,
            "finished": finished,
            "race_number": raceNumber
        ]

        if let playerId = playerId { dict["player_id"] = playerId }
        if let position = position { dict["position"] = position }

        return dict
    }

    static func from(row: [String: Any]) -> F1RaceModel? {
        guard let id = row["id"] as? String,
              let tournamentId = row["tournament_id"] as? String,
              let name = row["name"] as? String,
              let country = row["country"] as? String,
              let laps = row["laps"] as? Int,
              let dateTimestamp = row["date"] as? Int,
              let startPosition = row["start_position"] as? Int,
              let fastestLap = row["fastest_lap"] as? String,
              let pitStops = row["pit_stops"] as? Int,
              let finished = row["finished"] as? String else {
            return nil
        }

        return F1RaceModel(
            id: id,
            tournamentId: tournamentId,
            playerId: row["player_id"] as? String,
            name: name,
            country: country,
            laps: laps,
            date: Date(timeIntervalSince1970: TimeInterval(dateTimestamp)),
            position: row["position"] as? Int,
            startPosition: startPosition,
            fastestLap: fastestLap,
            pitStops: pitStops,
            finished: finished,
            raceNumber: row["race_number"] as? Int ?? 0
        )
    }
}

// MARK: - F1 Team Table Model
struct F1TeamTableModel: Codable, Identifiable {
    var id: String
    var tournamentId: String
    var teamName: String
    var totalPoints: Int
    var wins: Int
    var fastestLaps: Int
    var podiums: Int

    init(id: String = UUID().uuidString,
         tournamentId: String,
         teamName: String,
         totalPoints: Int = 0,
         wins: Int = 0,
         fastestLaps: Int = 0,
         podiums: Int = 0) {
        self.id = id
        self.tournamentId = tournamentId
        self.teamName = teamName
        self.totalPoints = totalPoints
        self.wins = wins
        self.fastestLaps = fastestLaps
        self.podiums = podiums
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "tournament_id": tournamentId,
            "team_name": teamName,
            "total_points": totalPoints,
            "wins": wins,
            "fastest_laps": fastestLaps,
            "podiums": podiums
        ]
    }

    static func from(row: [String: Any]) -> F1TeamTableModel? {
        guard let id = row["id"] as? String,
              let tournamentId = row["tournament_id"] as? String,
              let teamName = row["team_name"] as? String else {
            return nil
        }

        return F1TeamTableModel(
            id: id,
            tournamentId: tournamentId,
            teamName: teamName,
            totalPoints: row["total_points"] as? Int ?? 0,
            wins: row["wins"] as? Int ?? 0,
            fastestLaps: row["fastest_laps"] as? Int ?? 0,
            podiums: row["podiums"] as? Int ?? 0
        )
    }
}

// MARK: - F1 Player Table Model
struct F1PlayerTableModel: Codable, Identifiable {
    var id: String
    var tournamentId: String
    var playerId: String
    var totalPoints: Int
    var wins: Int
    var fastestLaps: Int
    var podiums: Int

    init(id: String = UUID().uuidString,
         tournamentId: String,
         playerId: String,
         totalPoints: Int = 0,
         wins: Int = 0,
         fastestLaps: Int = 0,
         podiums: Int = 0) {
        self.id = id
        self.tournamentId = tournamentId
        self.playerId = playerId
        self.totalPoints = totalPoints
        self.wins = wins
        self.fastestLaps = fastestLaps
        self.podiums = podiums
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "tournament_id": tournamentId,
            "player_id": playerId,
            "total_points": totalPoints,
            "wins": wins,
            "fastest_laps": fastestLaps,
            "podiums": podiums
        ]
    }

    static func from(row: [String: Any]) -> F1PlayerTableModel? {
        guard let id = row["id"] as? String,
              let tournamentId = row["tournament_id"] as? String,
              let playerId = row["player_id"] as? String else {
            return nil
        }

        return F1PlayerTableModel(
            id: id,
            tournamentId: tournamentId,
            playerId: playerId,
            totalPoints: row["total_points"] as? Int ?? 0,
            wins: row["wins"] as? Int ?? 0,
            fastestLaps: row["fastest_laps"] as? Int ?? 0,
            podiums: row["podiums"] as? Int ?? 0
        )
    }
}

// MARK: - App User Model
struct AppUserModel: Codable, Identifiable {
    var id: String
    var email: String
    var hashedPassword: String
    var createdAt: Date

    init(id: String = UUID().uuidString,
         email: String,
         hashedPassword: String,
         createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.hashedPassword = hashedPassword
        self.createdAt = createdAt
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "hashed_password": hashedPassword,
            "created_at": Int(createdAt.timeIntervalSince1970)
        ]
    }

    static func from(row: [String: Any]) -> AppUserModel? {
        guard let id = row["id"] as? String,
              let email = row["email"] as? String,
              let hashedPassword = row["hashed_password"] as? String,
              let createdTimestamp = row["created_at"] as? Int else {
            return nil
        }

        return AppUserModel(
            id: id,
            email: email,
            hashedPassword: hashedPassword,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdTimestamp))
        )
    }
}
