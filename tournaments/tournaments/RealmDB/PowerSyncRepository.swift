//
//  PowerSyncRepository.swift
//  tournaments
//
//  Created by PowerSync Migration
//  Repository pattern for CRUD operations with PowerSync
//

import Foundation
import PowerSync
import Combine

/// Repository for performing CRUD operations with PowerSync
class PowerSyncRepository {

    private let manager: PowerSyncManager

    init(manager: PowerSyncManager = .shared) {
        self.manager = manager
    }

    // MARK: - Generic CRUD Operations

    /// Insert or update a record
    func upsert(table: String, data: [String: Any]) async throws {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let columns = data.keys.joined(separator: ", ")
        let placeholders = data.keys.map { _ in "?" }.joined(separator: ", ")
        let values = Array(data.values)

        let sql = """
            INSERT OR REPLACE INTO \(table) (\(columns))
            VALUES (\(placeholders))
            """

        try await db.execute(sql, values)
    }

    /// Delete a record by ID
    func delete(table: String, id: String) async throws {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "DELETE FROM \(table) WHERE id = ?"
        try await db.execute(sql, [id])
    }

    /// Fetch single record by ID
    func fetchById(table: String, id: String) async throws -> [String: Any]? {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM \(table) WHERE id = ? LIMIT 1"
        let results = try await db.getAll(sql, [id])
        return results.first
    }

    /// Fetch all records from a table
    func fetchAll(table: String) async throws -> [[String: Any]] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM \(table)"
        return try await db.getAll(sql, [])
    }

    /// Watch query and get reactive updates
    func watch(sql: String, parameters: [Any] = []) -> AnyPublisher<[[String: Any]], Error> {
        return manager.watch(sql, parameters: parameters)
    }

    // MARK: - Player Operations

    func createPlayer(_ player: PlayerModel) async throws {
        try await upsert(table: "players", data: player.toDictionary())
    }

    func updatePlayer(_ player: PlayerModel) async throws {
        try await upsert(table: "players", data: player.toDictionary())
    }

    func deletePlayer(id: String) async throws {
        try await delete(table: "players", id: id)
    }

    func fetchPlayer(id: String) async throws -> PlayerModel? {
        guard let row = try await fetchById(table: "players", id: id) else {
            return nil
        }
        return PlayerModel.from(row: row)
    }

    func fetchAllPlayers() async throws -> [PlayerModel] {
        let rows = try await fetchAll(table: "players")
        return rows.compactMap { PlayerModel.from(row: $0) }
    }

    func watchPlayers() -> AnyPublisher<[PlayerModel], Error> {
        return watch(sql: "SELECT * FROM players")
            .map { rows in
                rows.compactMap { PlayerModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Tournament Operations

    func createTournament(_ tournament: TournamentModel) async throws {
        try await upsert(table: "tournaments", data: tournament.toDictionary())
    }

    func updateTournament(_ tournament: TournamentModel) async throws {
        try await upsert(table: "tournaments", data: tournament.toDictionary())
    }

    func deleteTournament(id: String) async throws {
        try await delete(table: "tournaments", id: id)
    }

    func fetchTournament(id: String) async throws -> TournamentModel? {
        guard let row = try await fetchById(table: "tournaments", id: id) else {
            return nil
        }
        return TournamentModel.from(row: row)
    }

    func fetchAllTournaments() async throws -> [TournamentModel] {
        let rows = try await fetchAll(table: "tournaments")
        return rows.compactMap { TournamentModel.from(row: $0) }
    }

    func fetchTournamentsByOwner(owner: String) async throws -> [TournamentModel] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM tournaments WHERE owner = ?"
        let rows = try await db.getAll(sql, [owner])
        return rows.compactMap { TournamentModel.from(row: $0) }
    }

    func watchTournaments() -> AnyPublisher<[TournamentModel], Error> {
        return watch(sql: "SELECT * FROM tournaments ORDER BY created_date DESC")
            .map { rows in
                rows.compactMap { TournamentModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    func watchTournamentsByOwner(owner: String) -> AnyPublisher<[TournamentModel], Error> {
        return watch(sql: "SELECT * FROM tournaments WHERE owner = ? ORDER BY created_date DESC", parameters: [owner])
            .map { rows in
                rows.compactMap { TournamentModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Tournament Match Operations

    func createMatch(_ match: TournamentMatchModel) async throws {
        try await upsert(table: "tournament_matches", data: match.toDictionary())
    }

    func updateMatch(_ match: TournamentMatchModel) async throws {
        try await upsert(table: "tournament_matches", data: match.toDictionary())
    }

    func deleteMatch(id: String) async throws {
        try await delete(table: "tournament_matches", id: id)
    }

    func fetchMatch(id: String) async throws -> TournamentMatchModel? {
        guard let row = try await fetchById(table: "tournament_matches", id: id) else {
            return nil
        }
        return TournamentMatchModel.from(row: row)
    }

    func fetchMatchesForTournament(tournamentId: String) async throws -> [TournamentMatchModel] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM tournament_matches WHERE tournament_id = ? ORDER BY match_index"
        let rows = try await db.getAll(sql, [tournamentId])
        return rows.compactMap { TournamentMatchModel.from(row: $0) }
    }

    func watchMatchesForTournament(tournamentId: String) -> AnyPublisher<[TournamentMatchModel], Error> {
        return watch(sql: "SELECT * FROM tournament_matches WHERE tournament_id = ? ORDER BY match_index", parameters: [tournamentId])
            .map { rows in
                rows.compactMap { TournamentMatchModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Tournament Settings Operations

    func createSettings(_ settings: TournamentSettingsModel) async throws {
        try await upsert(table: "tournament_settings", data: settings.toDictionary())
    }

    func updateSettings(_ settings: TournamentSettingsModel) async throws {
        try await upsert(table: "tournament_settings", data: settings.toDictionary())
    }

    func fetchSettingsForTournament(tournamentId: String) async throws -> TournamentSettingsModel? {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM tournament_settings WHERE tournament_id = ? LIMIT 1"
        let rows = try await db.getAll(sql, [tournamentId])
        guard let row = rows.first else { return nil }
        return TournamentSettingsModel.from(row: row)
    }

    // MARK: - Tournament Table Operations

    func createTableEntry(_ entry: TournamentTableModel) async throws {
        try await upsert(table: "tournament_table", data: entry.toDictionary())
    }

    func updateTableEntry(_ entry: TournamentTableModel) async throws {
        try await upsert(table: "tournament_table", data: entry.toDictionary())
    }

    func fetchTableForTournament(tournamentId: String) async throws -> [TournamentTableModel] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM tournament_table WHERE tournament_id = ? ORDER BY points DESC, (goals_scored - goals_conceded) DESC"
        let rows = try await db.getAll(sql, [tournamentId])
        return rows.compactMap { TournamentTableModel.from(row: $0) }
    }

    func watchTableForTournament(tournamentId: String) -> AnyPublisher<[TournamentTableModel], Error> {
        return watch(sql: "SELECT * FROM tournament_table WHERE tournament_id = ? ORDER BY points DESC, (goals_scored - goals_conceded) DESC", parameters: [tournamentId])
            .map { rows in
                rows.compactMap { TournamentTableModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - F1 Race Operations

    func createRace(_ race: F1RaceModel) async throws {
        try await upsert(table: "f1_races", data: race.toDictionary())
    }

    func updateRace(_ race: F1RaceModel) async throws {
        try await upsert(table: "f1_races", data: race.toDictionary())
    }

    func fetchRacesForTournament(tournamentId: String) async throws -> [F1RaceModel] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM f1_races WHERE tournament_id = ? ORDER BY race_number"
        let rows = try await db.getAll(sql, [tournamentId])
        return rows.compactMap { F1RaceModel.from(row: $0) }
    }

    func watchRacesForTournament(tournamentId: String) -> AnyPublisher<[F1RaceModel], Error> {
        return watch(sql: "SELECT * FROM f1_races WHERE tournament_id = ? ORDER BY race_number", parameters: [tournamentId])
            .map { rows in
                rows.compactMap { F1RaceModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - F1 Team Table Operations

    func createTeamTable(_ entry: F1TeamTableModel) async throws {
        try await upsert(table: "f1_team_table", data: entry.toDictionary())
    }

    func updateTeamTable(_ entry: F1TeamTableModel) async throws {
        try await upsert(table: "f1_team_table", data: entry.toDictionary())
    }

    func fetchTeamTableForTournament(tournamentId: String) async throws -> [F1TeamTableModel] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM f1_team_table WHERE tournament_id = ? ORDER BY total_points DESC"
        let rows = try await db.getAll(sql, [tournamentId])
        return rows.compactMap { F1TeamTableModel.from(row: $0) }
    }

    func watchTeamTableForTournament(tournamentId: String) -> AnyPublisher<[F1TeamTableModel], Error> {
        return watch(sql: "SELECT * FROM f1_team_table WHERE tournament_id = ? ORDER BY total_points DESC", parameters: [tournamentId])
            .map { rows in
                rows.compactMap { F1TeamTableModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - F1 Player Table Operations

    func createPlayerTable(_ entry: F1PlayerTableModel) async throws {
        try await upsert(table: "f1_player_table", data: entry.toDictionary())
    }

    func updatePlayerTable(_ entry: F1PlayerTableModel) async throws {
        try await upsert(table: "f1_player_table", data: entry.toDictionary())
    }

    func fetchPlayerTableForTournament(tournamentId: String) async throws -> [F1PlayerTableModel] {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM f1_player_table WHERE tournament_id = ? ORDER BY total_points DESC"
        let rows = try await db.getAll(sql, [tournamentId])
        return rows.compactMap { F1PlayerTableModel.from(row: $0) }
    }

    func watchPlayerTableForTournament(tournamentId: String) -> AnyPublisher<[F1PlayerTableModel], Error> {
        return watch(sql: "SELECT * FROM f1_player_table WHERE tournament_id = ? ORDER BY total_points DESC", parameters: [tournamentId])
            .map { rows in
                rows.compactMap { F1PlayerTableModel.from(row: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - App User Operations

    func createUser(_ user: AppUserModel) async throws {
        try await upsert(table: "app_users", data: user.toDictionary())
    }

    func fetchUserByEmail(email: String) async throws -> AppUserModel? {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        let sql = "SELECT * FROM app_users WHERE email = ? LIMIT 1"
        let rows = try await db.getAll(sql, [email])
        guard let row = rows.first else { return nil }
        return AppUserModel.from(row: row)
    }

    // MARK: - Batch Operations

    /// Delete all data for a tournament (cascade delete)
    func deleteTournamentData(tournamentId: String) async throws {
        guard let db = manager.database else {
            throw PowerSyncError.notInitialized
        }

        // Delete in correct order to avoid foreign key issues
        try await db.execute("DELETE FROM f1_races WHERE tournament_id = ?", [tournamentId])
        try await db.execute("DELETE FROM f1_team_table WHERE tournament_id = ?", [tournamentId])
        try await db.execute("DELETE FROM f1_player_table WHERE tournament_id = ?", [tournamentId])
        try await db.execute("DELETE FROM tournament_matches WHERE tournament_id = ?", [tournamentId])
        try await db.execute("DELETE FROM tournament_table WHERE tournament_id = ?", [tournamentId])
        try await db.execute("DELETE FROM tournament_settings WHERE tournament_id = ?", [tournamentId])
        try await db.execute("DELETE FROM tournaments WHERE id = ?", [tournamentId])
    }
}
