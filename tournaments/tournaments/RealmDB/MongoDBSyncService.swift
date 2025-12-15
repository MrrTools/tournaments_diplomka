//
//  MongoDBSyncService.swift
//  tournaments
//
//  Created for hybrid Realm + MongoDB solution
//  Syncs Realm changes to MongoDB Atlas via Data API
//

import Foundation
import RealmSwift
import Combine

/// Service pre synchronizáciu Realm dát do MongoDB Atlas
/// Používa MongoDB Atlas Data API pre zápis bez Realm Sync
class MongoDBSyncService: ObservableObject {

    static let shared = MongoDBSyncService()

    // MARK: - Configuration

    private let mongoDBDataAPIURL: String
    private let mongoDBAPIKey: String
    private let databaseName: String
    private let clusterName: String

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [String] = []

    private var syncQueue: DispatchQueue
    private var pendingChanges: Set<String> = []

    // MARK: - Initialization

    init(mongoDBDataAPIURL: String = "",
         mongoDBAPIKey: String = "",
         databaseName: String = "tournaments_db",
         clusterName: String = "Cluster0") {
        self.mongoDBDataAPIURL = mongoDBDataAPIURL
        self.mongoDBAPIKey = mongoDBAPIKey
        self.databaseName = databaseName
        self.clusterName = clusterName
        self.syncQueue = DispatchQueue(label: "com.tournaments.mongodb.sync", qos: .background)
    }

    // MARK: - Configuration Methods

    /// Nastavte MongoDB credentials po inicializácii
    var _dataAPIURL: String = ""
    var _apiKey: String = ""
    var _database: String = "tournaments_db"
    var _cluster: String = "Cluster0"

    func configure(dataAPIURL: String, apiKey: String, database: String = "tournaments_db", cluster: String = "Cluster0") {
        self._dataAPIURL = dataAPIURL
        self._apiKey = apiKey
        self._database = database
        self._cluster = cluster
    }

    // MARK: - Sync Methods

    /// Synchronizuje Tournament do MongoDB
    func syncTournament(_ tournament: Tournament) async throws {
        guard !mongoDBAPIKey.isEmpty else {
            throw MongoDBSyncError.notConfigured
        }

        let document = tournamentToDocument(tournament)
        try await upsertDocument(collection: "tournaments", document: document, id: tournament._id.stringValue)

        // Sync related entities
        for player in tournament.players {
            try await syncPlayer(player)
        }

        for match in tournament.matches {
            try await syncMatch(match)
        }

        for tableEntry in tournament.table {
            try await syncTableEntry(tableEntry)
        }

        if let settings = tournament.settings.first {
            try await syncSettings(settings)
        }

        lastSyncDate = Date()
    }

    /// Synchronizuje Player do MongoDB
    func syncPlayer(_ player: Player) async throws {
        let document = playerToDocument(player)
        try await upsertDocument(collection: "players", document: document, id: player._id.stringValue)
    }

    /// Synchronizuje Match do MongoDB
    func syncMatch(_ match: TournamentMatch) async throws {
        let document = matchToDocument(match)
        try await upsertDocument(collection: "tournament_matches", document: document, id: match._id.stringValue)
    }

    /// Synchronizuje Table Entry do MongoDB
    func syncTableEntry(_ entry: TournamentTable) async throws {
        let document = tableToDocument(entry)
        try await upsertDocument(collection: "tournament_table", document: document, id: entry._id.stringValue)
    }

    /// Synchronizuje Settings do MongoDB
    func syncSettings(_ settings: TournamentSettings) async throws {
        let document = settingsToDocument(settings)
        try await upsertDocument(collection: "tournament_settings", document: document, id: settings._id.stringValue)
    }

    /// Synchronizuje F1 Race do MongoDB
    func syncF1Race(_ race: F1Race) async throws {
        let document = f1RaceToDocument(race)
        try await upsertDocument(collection: "f1_races", document: document, id: race._id.stringValue)
    }

    /// Synchronizuje F1 Team Table do MongoDB
    func syncF1TeamTable(_ table: F1TeamTable) async throws {
        let document = f1TeamTableToDocument(table)
        try await upsertDocument(collection: "f1_team_table", document: document, id: table._id.stringValue)
    }

    /// Synchronizuje F1 Player Table do MongoDB
    func syncF1PlayerTable(_ table: F1PlayerTable) async throws {
        let document = f1PlayerTableToDocument(table)
        try await upsertDocument(collection: "f1_player_table", document: document, id: table._id.stringValue)
    }

    /// Vymaže Tournament z MongoDB
    func deleteTournament(id: String) async throws {
        try await deleteDocument(collection: "tournaments", id: id)
    }

    /// Synchronizuje všetky turnaje z Realm do MongoDB
    func syncAllTournaments() async throws {
        guard let realm = RealmManager.shared.realm else {
            throw MongoDBSyncError.realmNotInitialized
        }

        DispatchQueue.main.async {
            self.isSyncing = true
        }

        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }

        let tournaments = realm.objects(Tournament.self)

        for tournament in tournaments {
            do {
                try await syncTournament(tournament)
            } catch {
                DispatchQueue.main.async {
                    self.syncErrors.append("Failed to sync tournament \(tournament.name): \(error.localizedDescription)")
                }
            }
        }

        lastSyncDate = Date()
    }

    // MARK: - Download from MongoDB (Pull)

    /// Stiahne všetky dáta z MongoDB a importuje do Realm (pri prihlásení)
    func downloadFromMongoDBOnLogin(userEmail: String) async throws {
        guard let realm = RealmManager.shared.realm else {
            throw MongoDBSyncError.realmNotInitialized
        }

        guard !_apiKey.isEmpty else {
            throw MongoDBSyncError.notConfigured
        }

        DispatchQueue.main.async {
            self.isSyncing = true
        }

        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }

        do {
            // 1. Stiahni turnaje pre tohto používateľa
            let tournaments = try await fetchTournamentsFromMongoDB(owner: userEmail)

            // 2. Stiahni všetkých hráčov
            let players = try await fetchPlayersFromMongoDB()

            // 3. Import do Realm
            try realm.write {
                // Import players first (dependencies)
                for playerDoc in players {
                    if let player = documentToPlayer(playerDoc) {
                        realm.add(player, update: .modified)
                    }
                }

                // Import tournaments
                for tournamentDoc in tournaments {
                    if let tournament = documentToTournament(tournamentDoc) {
                        realm.add(tournament, update: .modified)
                    }
                }
            }

            // 4. Stiahni súvisiace entity pre každý turnaj
            for tournamentDoc in tournaments {
                guard let tournamentId = tournamentDoc["_id"] as? String else { continue }

                // Matches
                let matches = try await fetchMatchesFromMongoDB(tournamentId: tournamentId)
                // Settings
                let settings = try await fetchSettingsFromMongoDB(tournamentId: tournamentId)
                // Table
                let tables = try await fetchTableFromMongoDB(tournamentId: tournamentId)

                // Import do Realm
                try realm.write {
                    for matchDoc in matches {
                        if let match = documentToMatch(matchDoc) {
                            realm.add(match, update: .modified)
                        }
                    }

                    for settingsDoc in settings {
                        if let setting = documentToSettings(settingsDoc) {
                            realm.add(setting, update: .modified)
                        }
                    }

                    for tableDoc in tables {
                        if let table = documentToTable(tableDoc) {
                            realm.add(table, update: .modified)
                        }
                    }
                }
            }

            lastSyncDate = Date()
            print("Successfully downloaded data from MongoDB for user: \(userEmail)")

        } catch {
            DispatchQueue.main.async {
                self.syncErrors.append("Download failed: \(error.localizedDescription)")
            }
            throw error
        }
    }

    /// Fetch tournaments from MongoDB
    private func fetchTournamentsFromMongoDB(owner: String) async throws -> [[String: Any]] {
        let endpoint = "\(_dataAPIURL)/action/find"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(_apiKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": _cluster,
            "database": _database,
            "collection": "tournaments",
            "filter": ["owner": owner]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MongoDBSyncError.syncFailed("Failed to fetch tournaments")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["documents"] as? [[String: Any]]) ?? []
    }

    /// Fetch players from MongoDB
    private func fetchPlayersFromMongoDB() async throws -> [[String: Any]] {
        let endpoint = "\(_dataAPIURL)/action/find"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(_apiKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": _cluster,
            "database": _database,
            "collection": "players",
            "filter": [:]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MongoDBSyncError.syncFailed("Failed to fetch players")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["documents"] as? [[String: Any]]) ?? []
    }

    /// Fetch matches for tournament from MongoDB
    private func fetchMatchesFromMongoDB(tournamentId: String) async throws -> [[String: Any]] {
        let endpoint = "\(_dataAPIURL)/action/find"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(_apiKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": _cluster,
            "database": _database,
            "collection": "tournament_matches",
            "filter": ["tournamentId": tournamentId]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MongoDBSyncError.syncFailed("Failed to fetch matches")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["documents"] as? [[String: Any]]) ?? []
    }

    /// Fetch settings for tournament from MongoDB
    private func fetchSettingsFromMongoDB(tournamentId: String) async throws -> [[String: Any]] {
        let endpoint = "\(_dataAPIURL)/action/find"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(_apiKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": _cluster,
            "database": _database,
            "collection": "tournament_settings",
            "filter": ["tournamentId": tournamentId]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MongoDBSyncError.syncFailed("Failed to fetch settings")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["documents"] as? [[String: Any]]) ?? []
    }

    /// Fetch table for tournament from MongoDB
    private func fetchTableFromMongoDB(tournamentId: String) async throws -> [[String: Any]] {
        let endpoint = "\(_dataAPIURL)/action/find"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(_apiKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": _cluster,
            "database": _database,
            "collection": "tournament_table",
            "filter": ["tournamentId": tournamentId]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MongoDBSyncError.syncFailed("Failed to fetch table")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["documents"] as? [[String: Any]]) ?? []
    }

    // MARK: - MongoDB Data API Methods

    /// Insert or Update document v MongoDB
    private func upsertDocument(collection: String, document: [String: Any], id: String) async throws {
        let endpoint = "\(mongoDBDataAPIURL)/action/updateOne"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(mongoDBAPIKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": clusterName,
            "database": databaseName,
            "collection": collection,
            "filter": ["_id": id],
            "update": [
                "$set": document
            ],
            "upsert": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MongoDBSyncError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MongoDBSyncError.syncFailed(errorMessage)
        }
    }

    /// Delete document z MongoDB
    private func deleteDocument(collection: String, id: String) async throws {
        let endpoint = "\(mongoDBDataAPIURL)/action/deleteOne"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(mongoDBAPIKey, forHTTPHeaderField: "api-key")

        let body: [String: Any] = [
            "dataSource": clusterName,
            "database": databaseName,
            "collection": collection,
            "filter": ["_id": id]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MongoDBSyncError.syncFailed("Failed to delete document")
        }
    }

    // MARK: - Conversion Methods (Realm -> MongoDB Document)

    private func tournamentToDocument(_ tournament: Tournament) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": tournament._id.stringValue,
            "name": tournament.name,
            "owner": tournament.owner,
            "sport": tournament.sport,
            "type": tournament.type,
            "createdDate": tournament.createdDate.timeIntervalSince1970
        ]

        if let groupNumber = tournament.groupNumber { doc["groupNumber"] = groupNumber }
        if let numberOfAdvancePlayers = tournament.numberOfAdvancePlayers { doc["numberOfAdvancePlayers"] = numberOfAdvancePlayers }
        if let numberOfGroups = tournament.numberOfGroups { doc["numberOfGroups"] = numberOfGroups }
        if let playOFFMatches = tournament.playOFFMatches { doc["playOFFMatches"] = playOFFMatches }
        if let numberOfRaces = tournament.numberOfRaces { doc["numberOfRaces"] = numberOfRaces }
        if let riposeFinal = tournament.riposeFinal { doc["riposeFinal"] = riposeFinal }
        if let riposeKnockOut = tournament.riposeKnockOut { doc["riposeKnockOut"] = riposeKnockOut }
        if let riposeMatches = tournament.riposeMatches { doc["riposeMatches"] = riposeMatches }
        if let email = tournament.email { doc["email"] = email }

        // Store references to related entities
        doc["playerIds"] = tournament.players.map { $0._id.stringValue }
        doc["matchIds"] = tournament.matches.map { $0._id.stringValue }

        return doc
    }

    private func playerToDocument(_ player: Player) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": player._id.stringValue,
            "name": player.name
        ]

        if let team = player.team { doc["team"] = team }
        if let photoData = player.photoData {
            doc["photoData"] = photoData.base64EncodedString()
        }

        return doc
    }

    private func matchToDocument(_ match: TournamentMatch) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": match._id.stringValue,
            "player1Score": match.player1Score,
            "player2Score": match.player2Score,
            "player1ScoreRematch": match.player1ScoreRematch,
            "player2ScoreRematch": match.player2ScoreRematch,
            "fixturesRound": match.fixturesRound,
            "matchDate": match.matchDate.timeIntervalSince1970,
            "matchIndex": match.matchIndex,
            "groupIndex": match.groupIndex,
            "rematchFlag": match.rematchFlag
        ]

        if let player1 = match.player1 { doc["player1Id"] = player1._id.stringValue }
        if let player2 = match.player2 { doc["player2Id"] = player2._id.stringValue }
        if let setsString = match.setsString { doc["setsString"] = setsString }
        if let tournament = match.tournament { doc["tournamentId"] = tournament._id.stringValue }

        return doc
    }

    private func tableToDocument(_ table: TournamentTable) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": table._id.stringValue,
            "points": table.points,
            "goalsScored": table.goalsScored,
            "goalsConceded": table.goalsConceded,
            "wins": table.wins,
            "losses": table.losses,
            "draws": table.draws,
            "groupIndex": table.groupIndex
        ]

        if let player = table.player { doc["playerId"] = player._id.stringValue }
        if let tournament = table.tournament { doc["tournamentId"] = tournament._id.stringValue }

        return doc
    }

    private func settingsToDocument(_ settings: TournamentSettings) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": settings._id.stringValue,
            "winPoints": settings.winPoints,
            "losePoints": settings.losePoints,
            "drawPoints": settings.drawPoints
        ]

        if let tournament = settings.tournament { doc["tournamentId"] = tournament._id.stringValue }

        return doc
    }

    private func f1RaceToDocument(_ race: F1Race) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": race._id.stringValue,
            "name": race.name,
            "country": race.country,
            "laps": race.laps,
            "date": race.date.timeIntervalSince1970,
            "startPosition": race.startPosition,
            "fastestLap": race.fastestLap,
            "pitStops": race.pitStops,
            "finished": race.finished,
            "raceNumber": race.raceNumber
        ]

        if let player = race.player { doc["playerId"] = player._id.stringValue }
        if let position = race.position { doc["position"] = position }
        if let tournament = race.tournament { doc["tournamentId"] = tournament._id.stringValue }

        return doc
    }

    private func f1TeamTableToDocument(_ table: F1TeamTable) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": table._id.stringValue,
            "teamName": table.teamName,
            "totalPoints": table.totalPoints,
            "wins": table.wins,
            "fastestLaps": table.fastestLaps,
            "podiums": table.podiums
        ]

        if let tournament = table.tournament { doc["tournamentId"] = tournament._id.stringValue }

        return doc
    }

    private func f1PlayerTableToDocument(_ table: F1PlayerTable) -> [String: Any] {
        var doc: [String: Any] = [
            "_id": table._id.stringValue,
            "totalPoints": table.totalPoints,
            "wins": table.wins,
            "fastestLaps": table.fastestLaps,
            "podiums": table.podiums
        ]

        if let player = table.player { doc["playerId"] = player._id.stringValue }
        if let tournament = table.tournament { doc["tournamentId"] = tournament._id.stringValue }

        return doc
    }

    // MARK: - Conversion Methods (MongoDB Document -> Realm)

    /// Convert MongoDB document to Player Realm object
    private func documentToPlayer(_ doc: [String: Any]) -> Player? {
        guard let idString = doc["_id"] as? String,
              let name = doc["name"] as? String else {
            return nil
        }

        let player = Player()
        player._id = try! ObjectId(string: idString)
        player.name = name
        player.team = doc["team"] as? String

        if let photoBase64 = doc["photoData"] as? String {
            player.photoData = Data(base64Encoded: photoBase64)
        }

        return player
    }

    /// Convert MongoDB document to Tournament Realm object
    private func documentToTournament(_ doc: [String: Any]) -> Tournament? {
        guard let idString = doc["_id"] as? String,
              let name = doc["name"] as? String,
              let owner = doc["owner"] as? String,
              let sport = doc["sport"] as? String,
              let type = doc["type"] as? String else {
            return nil
        }

        let tournament = Tournament()
        tournament._id = try! ObjectId(string: idString)
        tournament.name = name
        tournament.owner = owner
        tournament.sport = sport
        tournament.type = type

        tournament.groupNumber = doc["groupNumber"] as? Int
        tournament.numberOfAdvancePlayers = doc["numberOfAdvancePlayers"] as? Int
        tournament.numberOfGroups = doc["numberOfGroups"] as? Int
        tournament.playOFFMatches = doc["playOFFMatches"] as? Int
        tournament.numberOfRaces = doc["numberOfRaces"] as? Int
        tournament.riposeFinal = doc["riposeFinal"] as? Bool
        tournament.riposeKnockOut = doc["riposeKnockOut"] as? Bool
        tournament.riposeMatches = doc["riposeMatches"] as? Bool
        tournament.email = doc["email"] as? String

        if let timestamp = doc["createdDate"] as? TimeInterval {
            tournament.createdDate = Date(timeIntervalSince1970: timestamp)
        }

        return tournament
    }

    /// Convert MongoDB document to TournamentMatch Realm object
    private func documentToMatch(_ doc: [String: Any]) -> TournamentMatch? {
        guard let idString = doc["_id"] as? String,
              let realm = RealmManager.shared.realm else {
            return nil
        }

        let match = TournamentMatch()
        match._id = try! ObjectId(string: idString)

        match.player1Score = doc["player1Score"] as? Int ?? 0
        match.player2Score = doc["player2Score"] as? Int ?? 0
        match.player1ScoreRematch = doc["player1ScoreRematch"] as? Int ?? 0
        match.player2ScoreRematch = doc["player2ScoreRematch"] as? Int ?? 0
        match.fixturesRound = doc["fixturesRound"] as? Int ?? 0
        match.matchIndex = doc["matchIndex"] as? Int ?? 0
        match.groupIndex = doc["groupIndex"] as? Int ?? 0
        match.rematchFlag = doc["rematchFlag"] as? Int ?? 0
        match.setsString = doc["setsString"] as? String

        if let timestamp = doc["matchDate"] as? TimeInterval {
            match.matchDate = Date(timeIntervalSince1970: timestamp)
        }

        // Link to Player1
        if let player1IdString = doc["player1Id"] as? String,
           let player1ObjectId = try? ObjectId(string: player1IdString) {
            match.player1 = realm.object(ofType: Player.self, forPrimaryKey: player1ObjectId)
        }

        // Link to Player2
        if let player2IdString = doc["player2Id"] as? String,
           let player2ObjectId = try? ObjectId(string: player2IdString) {
            match.player2 = realm.object(ofType: Player.self, forPrimaryKey: player2ObjectId)
        }

        // Link to Tournament
        if let tournamentIdString = doc["tournamentId"] as? String,
           let tournamentObjectId = try? ObjectId(string: tournamentIdString) {
            match.tournament = realm.object(ofType: Tournament.self, forPrimaryKey: tournamentObjectId)
        }

        return match
    }

    /// Convert MongoDB document to TournamentSettings Realm object
    private func documentToSettings(_ doc: [String: Any]) -> TournamentSettings? {
        guard let idString = doc["_id"] as? String,
              let realm = RealmManager.shared.realm else {
            return nil
        }

        let settings = TournamentSettings()
        settings._id = try! ObjectId(string: idString)
        settings.winPoints = doc["winPoints"] as? Int ?? 3
        settings.losePoints = doc["losePoints"] as? Int ?? 0
        settings.drawPoints = doc["drawPoints"] as? Int ?? 1

        // Link to Tournament
        if let tournamentIdString = doc["tournamentId"] as? String,
           let tournamentObjectId = try? ObjectId(string: tournamentIdString) {
            settings.tournament = realm.object(ofType: Tournament.self, forPrimaryKey: tournamentObjectId)
        }

        return settings
    }

    /// Convert MongoDB document to TournamentTable Realm object
    private func documentToTable(_ doc: [String: Any]) -> TournamentTable? {
        guard let idString = doc["_id"] as? String,
              let realm = RealmManager.shared.realm else {
            return nil
        }

        let table = TournamentTable()
        table._id = try! ObjectId(string: idString)
        table.points = doc["points"] as? Int ?? 0
        table.goalsScored = doc["goalsScored"] as? Int ?? 0
        table.goalsConceded = doc["goalsConceded"] as? Int ?? 0
        table.wins = doc["wins"] as? Int ?? 0
        table.losses = doc["losses"] as? Int ?? 0
        table.draws = doc["draws"] as? Int ?? 0
        table.groupIndex = doc["groupIndex"] as? Int ?? 0

        // Link to Player
        if let playerIdString = doc["playerId"] as? String,
           let playerObjectId = try? ObjectId(string: playerIdString) {
            table.player = realm.object(ofType: Player.self, forPrimaryKey: playerObjectId)
        }

        // Link to Tournament
        if let tournamentIdString = doc["tournamentId"] as? String,
           let tournamentObjectId = try? ObjectId(string: tournamentIdString) {
            table.tournament = realm.object(ofType: Tournament.self, forPrimaryKey: tournamentObjectId)
        }

        return table
    }
}

// MARK: - Errors

enum MongoDBSyncError: Error, LocalizedError {
    case notConfigured
    case realmNotInitialized
    case invalidResponse
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "MongoDB Data API nie je nakonfigurované"
        case .realmNotInitialized:
            return "Realm nie je inicializovaný"
        case .invalidResponse:
            return "Neplatná odpoveď z MongoDB"
        case .syncFailed(let message):
            return "Synchronizácia zlyhala: \(message)"
        }
    }
}
