//
//  MongoDBManager.swift
//  tournaments
//
//  MongoDB connection manager pre priamy zápis do MongoDB databázy
//

import Foundation
// POZNÁMKA: MongoDB Swift Driver musí byť pridaný cez Swift Package Manager
// V Xcode: File -> Add Package Dependencies...
// URL: https://github.com/mongodb/mongo-swift-driver
// Version: 1.3.1 alebo novšia

// Import MongoDB driver - odkomentujte po pridaní balíčka
// import MongoSwift

class MongoDBManager: ObservableObject {

    static let shared = MongoDBManager()

    // MongoDB connection parametre
    private let connectionString = "mongodb://localhost:27017" // TODO: Upraviť na produkčnú URI
    private let databaseName = "tournaments_db"

    // MongoDB client a databáza
    // private var client: MongoClient?
    // private var database: MongoDatabase?

    @Published var isConnected = false

    private init() {
        // Inicializácia sa uskutoční až pri volaní connect()
    }

    // MARK: - Connection

    func connect() async throws {
        /* Po pridaní MongoDB Swift Driver odkomentujte tento kód:

        do {
            // Vytvorenie MongoDB klienta
            client = try MongoClient(connectionString)
            database = client?.db(databaseName)

            // Test pripojenia
            let command: Document = ["ping": 1]
            _ = try await database?.runCommand(command)

            DispatchQueue.main.async {
                self.isConnected = true
            }
            print("MongoDB connection successful")
        } catch {
            print("MongoDB connection failed: \(error)")
            throw error
        }
        */

        // Dočasné riešenie - simulácia pripojenia
        DispatchQueue.main.async {
            self.isConnected = true
        }
        print("MongoDB manager ready (driver not yet installed)")
    }

    func disconnect() {
        /* Po pridaní MongoDB Swift Driver odkomentujte:

        client?.syncShutdown()
        client = nil
        database = nil

        DispatchQueue.main.async {
            self.isConnected = false
        }
        */

        DispatchQueue.main.async {
            self.isConnected = false
        }
    }

    // MARK: - Write Operations

    // Pridanie turnaja do MongoDB
    func insertTournament(_ tournament: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver odkomentujte:

        guard let collection = database?.collection("tournaments") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = Document(tournament)
            _ = try await collection.insertOne(document)
            print("Tournament inserted to MongoDB: \(tournament["name"] ?? "unknown")")
        } catch {
            print("Failed to insert tournament: \(error)")
            throw error
        }
        */

        // Dočasné riešenie - simulácia zápisu
        print("MongoDB insert simulation - Tournament: \(tournament["name"] ?? "unknown")")
    }

    // Aktualizácia turnaja v MongoDB
    func updateTournament(id: String, updates: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver odkomentujte:

        guard let collection = database?.collection("tournaments") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: Document = ["_id": .string(id)]
            let update: Document = ["$set": .document(Document(updates))]
            _ = try await collection.updateOne(filter: filter, update: update)
            print("Tournament updated in MongoDB: \(id)")
        } catch {
            print("Failed to update tournament: \(error)")
            throw error
        }
        */

        // Dočasné riešenie
        print("MongoDB update simulation - ID: \(id)")
    }

    // Pridanie zápasu do MongoDB
    func insertMatch(_ match: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver:

        guard let collection = database?.collection("matches") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = Document(match)
            _ = try await collection.insertOne(document)
            print("Match inserted to MongoDB")
        } catch {
            print("Failed to insert match: \(error)")
            throw error
        }
        */

        print("MongoDB insert simulation - Match")
    }

    // Aktualizácia zápasu v MongoDB
    func updateMatch(id: String, updates: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver:

        guard let collection = database?.collection("matches") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: Document = ["_id": .string(id)]
            let update: Document = ["$set": .document(Document(updates))]
            _ = try await collection.updateOne(filter: filter, update: update)
            print("Match updated in MongoDB: \(id)")
        } catch {
            print("Failed to update match: \(error)")
            throw error
        }
        */

        print("MongoDB update simulation - Match ID: \(id)")
    }

    // Pridanie používateľa do MongoDB
    func insertUser(_ user: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver:

        guard let collection = database?.collection("users") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = Document(user)
            _ = try await collection.insertOne(document)
            print("User inserted to MongoDB: \(user["email"] ?? "unknown")")
        } catch {
            print("Failed to insert user: \(error)")
            throw error
        }
        */

        print("MongoDB insert simulation - User: \(user["email"] ?? "unknown")")
    }

    // Pridanie F1 závodu do MongoDB
    func insertF1Race(_ race: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver:

        guard let collection = database?.collection("f1_races") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = Document(race)
            _ = try await collection.insertOne(document)
            print("F1 Race inserted to MongoDB")
        } catch {
            print("Failed to insert F1 race: \(error)")
            throw error
        }
        */

        print("MongoDB insert simulation - F1 Race")
    }

    // Aktualizácia tabuľky v MongoDB
    func updateTable(tournamentId: String, table: [String: Any]) async throws {
        /* Po pridaní MongoDB Swift Driver:

        guard let collection = database?.collection("tables") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: Document = ["tournament_id": .string(tournamentId)]
            let update: Document = ["$set": .document(Document(table))]
            let options = UpdateOptions(upsert: true)
            _ = try await collection.updateOne(filter: filter, update: update, options: options)
            print("Table updated in MongoDB for tournament: \(tournamentId)")
        } catch {
            print("Failed to update table: \(error)")
            throw error
        }
        */

        print("MongoDB update simulation - Table for tournament: \(tournamentId)")
    }

    // Vymazanie turnaja z MongoDB
    func deleteTournament(id: String) async throws {
        /* Po pridaní MongoDB Swift Driver:

        guard let collection = database?.collection("tournaments") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: Document = ["_id": .string(id)]
            _ = try await collection.deleteOne(filter)

            // Vymazať aj súvisiace dáta
            try await database?.collection("matches").deleteMany(["tournament_id": .string(id)])
            try await database?.collection("tables").deleteMany(["tournament_id": .string(id)])

            print("Tournament and related data deleted from MongoDB: \(id)")
        } catch {
            print("Failed to delete tournament: \(error)")
            throw error
        }
        */

        print("MongoDB delete simulation - Tournament ID: \(id)")
    }
}

// MARK: - Helper Extensions

extension MongoDBManager {

    // Konverzia Realm objektu Tournament na Dictionary pre MongoDB
    func tournamentToDict(_ tournament: Any) -> [String: Any] {
        // TODO: Implementovať konverziu Realm Tournament objektu na Dictionary
        // Použiť Mirror alebo manuálne extrahovať properties
        return [:]
    }

    // Konverzia Realm objektu Match na Dictionary pre MongoDB
    func matchToDict(_ match: Any) -> [String: Any] {
        // TODO: Implementovať konverziu
        return [:]
    }
}

// MARK: - Errors

enum MongoDBError: Error {
    case notConnected
    case insertFailed
    case updateFailed
    case deleteFailed
    case queryFailed
}
