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
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // Provádějte migrace, pokud je potřeba
                }
                if oldSchemaVersion < 2 {
                    // Provádějte migrace, pokud je potřeba
                }
                if oldSchemaVersion < 3 {
                    // Provádějte migrace, pokud je potřeba
                }
            },
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
        
        // Inicializace Realm a kontrola, zda je soubor dostupný
        do {
            let realm = try Realm()
            print("Realm file path: \(realm.configuration.fileURL!)")
        } catch {
            // Pokusíme se vytvořit nový Realm soubor, pokud je původní poškozený nebo neexistuje
            _ = createNewRealm()
        }
    }
    
    @MainActor
    func initialize() async throws {
        
        // authentication
        user = try await app.login(credentials: Credentials.anonymous)
        
        self.configuration = user?.flexibleSyncConfiguration(initialSubscriptions: { subs in
                    
                    if let tournamentSub = subs.first(named: "all-tournaments") {
                        return
                    } else {
                        subs.append(QuerySubscription<Tournament>(name: "all-tournaments"))
                    }
                    
                    if let playerSub = subs.first(named: "all-players") {
                        return
                    } else {
                        subs.append(QuerySubscription<Player>(name: "all-players"))
                    }
                    
                    if let matchSub = subs.first(named: "all-matches") {
                        return
                    } else {
                        subs.append(QuerySubscription<Match>(name: "all-matches"))
                    }
            if let settingsSub = subs.first(named: "all-settings") {
                return
            } else {
                subs.append(QuerySubscription<TournamentSettings>(name: "all-settings"))
            }
            if let tableSub = subs.first(named: "all-table") {
                return
            } else {
                subs.append(QuerySubscription<TournamentTable>(name: "all-table"))
            }
                    
                }, rerunOnOpen: true)
                
                realm = try! await Realm(configuration: configuration!, downloadBeforeOpen: .always)
                
            }
    

    private func createNewRealm() -> Realm {
        let fileManager = FileManager.default
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL
        
        // Pokusíme se odstranit starý Realm soubor, pokud existuje
        if let defaultRealmPath = defaultRealmPath {
            do {
                try fileManager.removeItem(at: defaultRealmPath)
                print("Old Realm file deleted.")
            } catch {
                print("Error deleting old Realm file: \(error)")
            }
        }
        
        // Pokusíme se vytvořit nový Realm soubor
        do {
            let newRealm = try Realm()
            print("New Realm file created at: \(String(describing: newRealm.configuration.fileURL))")
            return newRealm
        } catch {
            fatalError("Error creating new Realm: \(error)")
        }
    }
}
