//
//  RealmManager.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import Foundation
import RealmSwift

class RealmManager: ObservableObject {
    
    let app: App
    
    @Published var realm: Realm?
    static let shared = RealmManager()
    @Published var user: User?
    @Published var configuration: Realm.Configuration?
    
    private init() {
        self.app = App(id: "application-1-ijrhwpn")
        
        // Konfigurace Realm s možností smazání souboru v případě potřeby migrace
        let config = Realm.Configuration(
            schemaVersion: 3,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
    }
    
    @MainActor
    func initialize() async throws {
        
        // authentication
        user = try await app.login(credentials: Credentials.anonymous)
        
        self.configuration = user?.flexibleSyncConfiguration(initialSubscriptions: { subs in
            
            if subs.first(named: "all-tournaments") == nil {
                subs.append(QuerySubscription<Tournament>(name: "all-tournaments"))
            }
            if subs.first(named: "all-players") == nil {
                subs.append(QuerySubscription<Player>(name: "all-players"))
            }
            if subs.first(named: "all-matches") == nil {
                subs.append(QuerySubscription<Match>(name: "all-matches"))
            }
            if subs.first(named: "all-settings") == nil {
                subs.append(QuerySubscription<TournamentSettings>(name: "all-settings"))
            }
            if subs.first(named: "all-table") == nil {
                subs.append(QuerySubscription<TournamentTable>(name: "all-table"))
            }
            
        }, rerunOnOpen: true)
        
        realm = try! await Realm(configuration: configuration!, downloadBeforeOpen: .always)
        
    }
}
