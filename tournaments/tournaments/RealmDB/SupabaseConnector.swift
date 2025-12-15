//
//  SupabaseConnector.swift
//  tournaments
//
//  Created by PowerSync Migration
//  Backend connector for Supabase integration with PowerSync
//

import Foundation
import PowerSync

/// Supabase backend connector for PowerSync
/// This class handles authentication and data upload to Supabase backend
class SupabaseConnector: PowerSyncBackendConnector {

    // MARK: - Configuration
    private let supabaseURL: String
    private let supabaseAnonKey: String
    private let powerSyncEndpoint: String

    /// Initialize Supabase connector
    /// - Parameters:
    ///   - supabaseURL: Your Supabase project URL (e.g., "https://xxx.supabase.co")
    ///   - supabaseAnonKey: Your Supabase anon/public key
    ///   - powerSyncEndpoint: Your PowerSync instance endpoint
    init(supabaseURL: String,
         supabaseAnonKey: String,
         powerSyncEndpoint: String) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
        self.powerSyncEndpoint = powerSyncEndpoint
    }

    // MARK: - PowerSyncBackendConnector Protocol

    /// Fetch credentials for PowerSync connection
    func fetchCredentials() async throws -> PowerSyncCredentials {
        // TODO: Implement proper authentication with Supabase
        // For now, using anonymous access
        // In production, you should:
        // 1. Get user session from Supabase Auth
        // 2. Extract access token from session
        // 3. Return credentials with that token

        // Example with Supabase Auth (requires supabase-swift package):
        /*
        do {
            let session = try await supabaseClient.auth.session
            return PowerSyncCredentials(
                endpoint: powerSyncEndpoint,
                token: session.accessToken
            )
        } catch {
            throw PowerSyncError.connectionFailed
        }
        */

        // Placeholder implementation for development:
        return PowerSyncCredentials(
            endpoint: powerSyncEndpoint,
            token: supabaseAnonKey
        )
    }

    /// Upload local changes to backend
    func uploadData(database: PowerSyncDatabase) async throws {
        // Get the next batch of changes to upload
        guard let transaction = try await database.getCrudBatch(limit: 100) else {
            // No more changes to upload
            return
        }

        do {
            // Process each operation in the transaction
            for operation in transaction.crud {
                try await processOperation(operation)
            }

            // Mark transaction as complete
            try await transaction.complete()

        } catch {
            // Transaction failed, will be retried later
            print("Failed to upload transaction: \(error)")
            throw error
        }
    }

    // MARK: - Private Methods

    /// Process a single CRUD operation
    private func processOperation(_ operation: CrudEntry) async throws {
        switch operation.op {
        case .INSERT, .UPDATE:
            try await upsertRow(
                table: operation.table,
                id: operation.id,
                data: operation.opData ?? [:]
            )

        case .DELETE:
            try await deleteRow(
                table: operation.table,
                id: operation.id
            )

        default:
            // Unknown operation type
            break
        }
    }

    /// Insert or update a row in Supabase
    private func upsertRow(table: String, id: String, data: [String: Any]) async throws {
        var mutableData = data
        mutableData["id"] = id

        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let jsonData = try JSONSerialization.data(withJSONObject: mutableData)
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PowerSyncError.queryFailed("Failed to upsert row in \(table)")
        }
    }

    /// Delete a row from Supabase
    private func deleteRow(table: String, id: String) async throws {
        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)?id=eq.\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PowerSyncError.queryFailed("Failed to delete row from \(table)")
        }
    }
}

// MARK: - Usage Example

/*
 To use this connector in your app:

 1. Initialize PowerSync manager:
 ```swift
 let manager = PowerSyncManager.shared
 try await manager.initialize()
 ```

 2. Create and connect the Supabase connector:
 ```swift
 let connector = SupabaseConnector(
     supabaseURL: "https://your-project.supabase.co",
     supabaseAnonKey: "your-anon-key",
     powerSyncEndpoint: "https://your-powersync-instance.powersync.com"
 )

 try await manager.database?.connect(connector: connector)
 ```

 3. Use the repository for data operations:
 ```swift
 let repository = PowerSyncRepository()
 let tournaments = try await repository.fetchAllTournaments()
 ```
 */
