//
//  RealmManager.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import Foundation
import RealmSwift

class RealmManager: ObservableObject {

    @Published var realm: Realm?
    static let shared = RealmManager()
    @Published var isInitialized = false

    private init() {
        // Konfigurácia lokálnej Realm databázy bez synchronizácie
        let config = Realm.Configuration(
            schemaVersion: 3,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
    }

    @MainActor
    func initialize() async {
        do {
            // Inicializácia lokálnej Realm databázy
            let realmInstance = try await Realm()
            realm = realmInstance
            isInitialized = true
        } catch {
            print("Error initializing Realm: \(error)")
        }
    }
}
