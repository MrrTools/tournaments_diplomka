//
//  RealmWithMongoDBManager.swift
//  tournaments
//
//  Hybrid Realm + MongoDB solution
//  Realm pre lokálnu databázu, MongoDB Atlas Data API pre cloud backup
//

import Foundation
import RealmSwift
import Combine

/// Rozšírený RealmManager s MongoDB synchronizáciou
class RealmWithMongoDBManager: ObservableObject {

    static let shared = RealmWithMongoDBManager()

    @Published var realm: Realm?
    @Published var isInitialized = false
    @Published var isSyncing = false

    private let mongoSync = MongoDBSyncService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Konfigurácia Realm s možnosťou migrácie
        let config = Realm.Configuration(
            schemaVersion: 3,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
    }

    /// Inicializácia Realm databázy (lokálna, bez cloud sync)
    @MainActor
    func initialize() async {
        do {
            // Otvorenie lokálnej Realm databázy (bez Realm Sync)
            realm = try Realm()

            DispatchQueue.main.async {
                self.isInitialized = true
            }

            print("Realm initialized successfully (local mode)")
        } catch {
            print("Error initializing Realm: \(error)")
        }
    }

    /// Konfigurácia MongoDB Data API pre cloud sync
    func configureMongoDBSync(dataAPIURL: String, apiKey: String, database: String = "tournaments_db", cluster: String = "Cluster0") {
        mongoSync.configure(dataAPIURL: dataAPIURL, apiKey: apiKey, database: database, cluster: cluster)
    }

    /// Synchronizácia z MongoDB pri prihlásení (download dát z cloudu)
    func syncFromMongoDBOnLogin(userEmail: String) async throws {
        DispatchQueue.main.async {
            self.isSyncing = true
        }

        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }

        try await mongoSync.downloadFromMongoDBOnLogin(userEmail: userEmail)
        print("Successfully synced data from MongoDB for user: \(userEmail)")
    }

    // MARK: - CRUD Operations with Auto-Sync

    /// Vytvorenie turnaja (Realm + MongoDB sync)
    func createTournament(_ tournament: Tournament, syncToMongoDB: Bool = true) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        // Zápis do lokálnej Realm databázy
        try realm.write {
            realm.add(tournament)
        }

        // Sync do MongoDB
        if syncToMongoDB {
            try await mongoSync.syncTournament(tournament)
        }
    }

    /// Aktualizácia turnaja (Realm + MongoDB sync)
    func updateTournament(_ tournament: Tournament, syncToMongoDB: Bool = true) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        // Aktualizácia v Realm
        try realm.write {
            realm.add(tournament, update: .modified)
        }

        // Sync do MongoDB
        if syncToMongoDB {
            try await mongoSync.syncTournament(tournament)
        }
    }

    /// Vymazanie turnaja (Realm + MongoDB sync)
    func deleteTournament(_ tournament: Tournament, syncToMongoDB: Bool = true) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        let tournamentId = tournament._id.stringValue

        // Vymazanie z Realm
        try realm.write {
            realm.delete(tournament)
        }

        // Sync do MongoDB
        if syncToMongoDB {
            try await mongoSync.deleteTournament(id: tournamentId)
        }
    }

    /// Vytvorenie hráča (Realm + MongoDB sync)
    func createPlayer(_ player: Player, syncToMongoDB: Bool = true) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        try realm.write {
            realm.add(player)
        }

        if syncToMongoDB {
            try await mongoSync.syncPlayer(player)
        }
    }

    /// Vytvorenie zápasu (Realm + MongoDB sync)
    func createMatch(_ match: TournamentMatch, syncToMongoDB: Bool = true) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        try realm.write {
            realm.add(match)
        }

        if syncToMongoDB {
            try await mongoSync.syncMatch(match)
        }
    }

    /// Aktualizácia zápasu (Realm + MongoDB sync)
    func updateMatch(_ match: TournamentMatch, syncToMongoDB: Bool = true) async throws {
        guard let realm = realm else {
            throw RealmError.notInitialized
        }

        try realm.write {
            realm.add(match, update: .modified)
        }

        if syncToMongoDB {
            try await mongoSync.syncMatch(match)
        }
    }

    // MARK: - Bulk Sync Operations

    /// Synchronizácia všetkých dát do MongoDB
    func syncAllToMongoDB() async throws {
        DispatchQueue.main.async {
            self.isSyncing = true
        }

        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }

        try await mongoSync.syncAllTournaments()
    }

    /// Automatická synchronizácia po zmene (background)
    func enableAutoSync(interval: TimeInterval = 300) {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    do {
                        try await self?.syncAllToMongoDB()
                        print("Auto-sync completed successfully")
                    } catch {
                        print("Auto-sync failed: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Query Methods (from Realm)

    func fetchAllTournaments() -> Results<Tournament>? {
        return realm?.objects(Tournament.self)
    }

    func fetchTournamentsByOwner(_ owner: String) -> Results<Tournament>? {
        return realm?.objects(Tournament.self).filter("owner == %@", owner)
    }

    func fetchAllPlayers() -> Results<Player>? {
        return realm?.objects(Player.self)
    }

    func fetchMatchesForTournament(_ tournament: Tournament) -> List<TournamentMatch> {
        return tournament.matches
    }
}

// MARK: - Errors

enum RealmError: Error, LocalizedError {
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Realm is not initialized"
        }
    }
}
