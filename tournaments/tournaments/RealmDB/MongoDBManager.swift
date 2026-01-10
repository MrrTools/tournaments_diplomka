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
 import MongoSwift

class MongoDBManager: ObservableObject {

    static let shared = MongoDBManager()

    // MongoDB connection parametre
    private let connectionString = "mongodb://localhost:27017" // TODO: Upraviť na produkčnú URI
    private let databaseName = "tournaments_db"

    // MongoDB client a databáza
    private var client: MongoClient?
    private var database: MongoDatabase?

    @Published var isConnected = false

    private init() {
        // Inicializácia sa uskutoční až pri volaní connect()
    }

    // MARK: - Connection

    func connect() async throws {
        do {
            // Vytvorenie MongoDB klienta
            client = try MongoClient(connectionString, using: nil)
            database = client?.db(databaseName)

            // Test pripojenia
            let command: BSONDocument = ["ping": .int32(1)]
            _ = try await database?.runCommand(command, options: nil)
        } catch {
            print("MongoDB connection failed: \(error)")
            throw error
        }
        
        await MainActor.run {
            self.isConnected = true
        }
        print("MongoDB connection successful")
    }

    func disconnect() async {
        // MongoDB Swift Driver používa close() pre async shutdown
        do {
            try await client?.close()
        } catch {
            print("Error closing MongoDB connection: \(error)")
        }
        client = nil
        database = nil

        await MainActor.run {
            self.isConnected = false
        }
    }

    // MARK: - Write Operations

    // Pridanie turnaja do MongoDB
    func insertTournament(_ tournament: [String: Any]) async throws {
        guard let collection = database?.collection("tournaments") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = try dictToBSON(tournament)
            _ = try await collection.insertOne(document)
            print("Tournament inserted to MongoDB: \(tournament["name"] ?? "unknown")")
        } catch {
            print("Failed to insert tournament: \(error)")
            throw error
        }
    }

    // Aktualizácia turnaja v MongoDB
    func updateTournament(id: String, updates: [String: Any]) async throws {
        guard let collection = database?.collection("tournaments") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: BSONDocument = ["_id": .string(id)]
            let updateDoc = try dictToBSON(updates)
            let update: BSONDocument = ["$set": .document(updateDoc)]
            _ = try await collection.updateOne(filter: filter, update: update)
            print("Tournament updated in MongoDB: \(id)")
        } catch {
            print("Failed to update tournament: \(error)")
            throw error
        }
    }

    // Pridanie zápasu do MongoDB
    func insertMatch(_ match: [String: Any]) async throws {
        guard let collection = database?.collection("matches") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = try dictToBSON(match)
            _ = try await collection.insertOne(document)
            print("Match inserted to MongoDB")
        } catch {
            print("Failed to insert match: \(error)")
            throw error
        }
    }

    // Aktualizácia zápasu v MongoDB
    func updateMatch(id: String, updates: [String: Any]) async throws {
        guard let collection = database?.collection("matches") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: BSONDocument = ["_id": .string(id)]
            let updateDoc = try dictToBSON(updates)
            let update: BSONDocument = ["$set": .document(updateDoc)]
            _ = try await collection.updateOne(filter: filter, update: update)
            print("Match updated in MongoDB: \(id)")
        } catch {
            print("Failed to update match: \(error)")
            throw error
        }
    }

    // Pridanie používateľa do MongoDB
    func insertUser(_ user: [String: Any]) async throws {
        guard let collection = database?.collection("users") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = try dictToBSON(user)
            _ = try await collection.insertOne(document)
            print("User inserted to MongoDB: \(user["email"] ?? "unknown")")
        } catch {
            print("Failed to insert user: \(error)")
            throw error
        }
    }

    // Pridanie F1 závodu do MongoDB
    func insertF1Race(_ race: [String: Any]) async throws {
        guard let collection = database?.collection("f1_races") else {
            throw MongoDBError.notConnected
        }

        do {
            let document = try dictToBSON(race)
            _ = try await collection.insertOne(document)
            print("F1 Race inserted to MongoDB")
        } catch {
            print("Failed to insert F1 race: \(error)")
            throw error
        }
    }

    // Aktualizácia tabuľky v MongoDB
    func updateTable(tournamentId: String, table: [String: Any]) async throws {
        guard let collection = database?.collection("tables") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: BSONDocument = ["tournament_id": .string(tournamentId)]
            let tableDoc = try dictToBSON(table)
            let update: BSONDocument = ["$set": .document(tableDoc)]
            let options = UpdateOptions(upsert: true)
            _ = try await collection.updateOne(filter: filter, update: update, options: options)
            print("Table updated in MongoDB for tournament: \(tournamentId)")
        } catch {
            print("Failed to update table: \(error)")
            throw error
        }
    }

    // Vymazanie turnaja z MongoDB
    func deleteTournament(id: String) async throws {
        guard let collection = database?.collection("tournaments") else {
            throw MongoDBError.notConnected
        }

        do {
            let filter: BSONDocument = ["_id": .string(id)]
            _ = try await collection.deleteOne(filter)

            // Vymazať aj súvisiace dáta
            let tournamentFilter: BSONDocument = ["tournament_id": .string(id)]
            _ = try await database?.collection("matches").deleteMany(tournamentFilter)
            _ = try await database?.collection("tables").deleteMany(tournamentFilter)

            print("Tournament and related data deleted from MongoDB: \(id)")
        } catch {
            print("Failed to delete tournament: \(error)")
            throw error
        }
    }
}

// MARK: - Helper Extensions

extension MongoDBManager {

    // Helper funkcia na konverziu Dictionary na BSONDocument
    private func dictToBSON(_ dict: [String: Any]) throws -> BSONDocument {
        var document = BSONDocument()
        
        for (key, value) in dict {
            switch value {
            case let stringValue as String:
                document[key] = .string(stringValue)
            case let intValue as Int:
                document[key] = .int64(Int64(intValue))
            case let int32Value as Int32:
                document[key] = .int32(int32Value)
            case let int64Value as Int64:
                document[key] = .int64(int64Value)
            case let doubleValue as Double:
                document[key] = .double(doubleValue)
            case let boolValue as Bool:
                document[key] = .bool(boolValue)
            case let dateValue as Date:
                document[key] = .datetime(dateValue)
            case let arrayValue as [Any]:
                document[key] = try .array(arrayToBSON(arrayValue))
            case let dictValue as [String: Any]:
                document[key] = try .document(dictToBSON(dictValue))
            case is NSNull:
                document[key] = .null
            default:
                // Pre neznáme typy použijeme string reprezentáciu
                document[key] = .string(String(describing: value))
            }
        }
        
        return document
    }
    
    // Helper funkcia na konverziu Array na BSON Array
    private func arrayToBSON(_ array: [Any]) throws -> [BSON] {
        return try array.map { value in
            switch value {
            case let stringValue as String:
                return .string(stringValue)
            case let intValue as Int:
                return .int64(Int64(intValue))
            case let int32Value as Int32:
                return .int32(int32Value)
            case let int64Value as Int64:
                return .int64(int64Value)
            case let doubleValue as Double:
                return .double(doubleValue)
            case let boolValue as Bool:
                return .bool(boolValue)
            case let dateValue as Date:
                return .datetime(dateValue)
            case let arrayValue as [Any]:
                return try .array(arrayToBSON(arrayValue))
            case let dictValue as [String: Any]:
                return try .document(dictToBSON(dictValue))
            case is NSNull:
                return .null
            default:
                return .string(String(describing: value))
            }
        }
    }

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
