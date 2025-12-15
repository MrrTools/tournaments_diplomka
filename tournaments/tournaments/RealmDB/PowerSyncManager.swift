//
//  PowerSyncManager.swift
//  tournaments
//
//  Created by PowerSync Migration
//  Migrated from Realm to PowerSync
//

import Foundation
import PowerSync
import Combine

/// PowerSync database manager for tournament application
/// Replaces RealmManager with PowerSync offline-first sync
class PowerSyncManager: ObservableObject {

    static let shared = PowerSyncManager()

    @Published var database: PowerSyncDatabase?
    @Published var isInitialized = false
    @Published var syncStatus: SyncStatus = .disconnected

    private var cancellables = Set<AnyCancellable>()

    /// Database schema defining all tables
    private let schema = Schema(tables: [
        // Players table
        Table(
            name: "players",
            columns: [
                .text("id"),
                .text("name"),
                .text("team"),
                .text("photo_data") // Base64 encoded image data
            ],
            indexes: [
                Index(name: "idx_players_id", columns: [.column("id")])
            ]
        ),

        // Tournaments table
        Table(
            name: "tournaments",
            columns: [
                .text("id"),
                .text("name"),
                .text("owner"),
                .text("sport"),
                .text("type"),
                .integer("group_number"),
                .integer("number_of_advance_players"),
                .integer("number_of_groups"),
                .integer("playoff_matches"),
                .integer("number_of_races"),
                .integer("ripose_final"), // boolean as integer
                .integer("ripose_knockout"), // boolean as integer
                .integer("ripose_matches"), // boolean as integer
                .text("email"),
                .integer("created_date") // Unix timestamp
            ],
            indexes: [
                Index(name: "idx_tournaments_id", columns: [.column("id")]),
                Index(name: "idx_tournaments_owner", columns: [.column("owner")])
            ]
        ),

        // Tournament Matches table
        Table(
            name: "tournament_matches",
            columns: [
                .text("id"),
                .text("tournament_id"),
                .text("player1_id"),
                .text("player2_id"),
                .integer("player1_score"),
                .integer("player2_score"),
                .integer("player1_score_rematch"),
                .integer("player2_score_rematch"),
                .text("sets_string"),
                .integer("fixtures_round"),
                .integer("match_date"), // Unix timestamp
                .integer("match_index"),
                .integer("group_index"),
                .integer("rematch_flag")
            ],
            indexes: [
                Index(name: "idx_matches_tournament", columns: [.column("tournament_id")]),
                Index(name: "idx_matches_id", columns: [.column("id")])
            ]
        ),

        // Tournament Settings table
        Table(
            name: "tournament_settings",
            columns: [
                .text("id"),
                .text("tournament_id"),
                .integer("win_points"),
                .integer("lose_points"),
                .integer("draw_points")
            ],
            indexes: [
                Index(name: "idx_settings_tournament", columns: [.column("tournament_id")])
            ]
        ),

        // Tournament Table (standings) table
        Table(
            name: "tournament_table",
            columns: [
                .text("id"),
                .text("tournament_id"),
                .text("player_id"),
                .integer("points"),
                .integer("goals_scored"),
                .integer("goals_conceded"),
                .integer("wins"),
                .integer("losses"),
                .integer("draws"),
                .integer("group_index")
            ],
            indexes: [
                Index(name: "idx_table_tournament", columns: [.column("tournament_id")]),
                Index(name: "idx_table_player", columns: [.column("player_id")])
            ]
        ),

        // F1 Race table
        Table(
            name: "f1_races",
            columns: [
                .text("id"),
                .text("tournament_id"),
                .text("player_id"),
                .text("name"),
                .text("country"),
                .integer("laps"),
                .integer("date"), // Unix timestamp
                .integer("position"),
                .integer("start_position"),
                .text("fastest_lap"),
                .integer("pit_stops"),
                .text("finished"),
                .integer("race_number")
            ],
            indexes: [
                Index(name: "idx_races_tournament", columns: [.column("tournament_id")])
            ]
        ),

        // F1 Team Table table
        Table(
            name: "f1_team_table",
            columns: [
                .text("id"),
                .text("tournament_id"),
                .text("team_name"),
                .integer("total_points"),
                .integer("wins"),
                .integer("fastest_laps"),
                .integer("podiums")
            ],
            indexes: [
                Index(name: "idx_team_table_tournament", columns: [.column("tournament_id")])
            ]
        ),

        // F1 Player Table table
        Table(
            name: "f1_player_table",
            columns: [
                .text("id"),
                .text("tournament_id"),
                .text("player_id"),
                .integer("total_points"),
                .integer("wins"),
                .integer("fastest_laps"),
                .integer("podiums")
            ],
            indexes: [
                Index(name: "idx_player_table_tournament", columns: [.column("tournament_id")]),
                Index(name: "idx_player_table_player", columns: [.column("player_id")])
            ]
        ),

        // App Users table
        Table(
            name: "app_users",
            columns: [
                .text("id"),
                .text("email"),
                .text("hashed_password"),
                .integer("created_at") // Unix timestamp
            ],
            indexes: [
                Index(name: "idx_users_email", columns: [.column("email")])
            ]
        )
    ])

    private init() {
        // Private initializer for singleton
    }

    /// Initialize PowerSync database
    /// - Parameters:
    ///   - logger: Optional logger for debugging
    @MainActor
    func initialize(logger: PSLogger? = nil) async throws {
        let dbLogger = logger ?? DefaultLogger(minSeverity: .info)

        // Create database with schema
        self.database = PowerSyncDatabase(
            schema: schema,
            logger: dbLogger
        )

        // TODO: Configure backend connector
        // This will need to be set up with your backend (Supabase, custom Postgres, etc.)
        // Example:
        // let connector = YourBackendConnector()
        // try await database?.connect(connector: connector)

        DispatchQueue.main.async {
            self.isInitialized = true
        }

        print("PowerSync database initialized successfully")
    }

    /// Get database instance
    func getDatabase() -> PowerSyncDatabase? {
        return database
    }

    /// Execute a query
    func execute(_ sql: String, parameters: [Any] = []) async throws {
        guard let db = database else {
            throw PowerSyncError.notInitialized
        }
        try await db.execute(sql, parameters)
    }

    /// Get query results
    func getAll(_ sql: String, parameters: [Any] = []) async throws -> [[String: Any]] {
        guard let db = database else {
            throw PowerSyncError.notInitialized
        }
        return try await db.getAll(sql, parameters)
    }

    /// Watch query results (reactive)
    func watch(_ sql: String, parameters: [Any] = []) -> AnyPublisher<[[String: Any]], Error> {
        guard let db = database else {
            return Fail(error: PowerSyncError.notInitialized).eraseToAnyPublisher()
        }

        // Create publisher that emits query results when data changes
        return db.watch(sql, parameters: parameters)
            .map { results in
                results.map { $0.toMap() }
            }
            .eraseToAnyPublisher()
    }
}

/// PowerSync specific errors
enum PowerSyncError: Error {
    case notInitialized
    case connectionFailed
    case queryFailed(String)

    var localizedDescription: String {
        switch self {
        case .notInitialized:
            return "PowerSync database is not initialized"
        case .connectionFailed:
            return "Failed to connect to sync backend"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        }
    }
}

/// Sync status enumeration
enum SyncStatus {
    case disconnected
    case connecting
    case connected
    case syncing
    case error(Error)
}
