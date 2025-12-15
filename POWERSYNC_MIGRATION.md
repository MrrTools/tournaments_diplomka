# PowerSync Migration Guide

Tento dokument popisuje migráciu z MongoDB Realm na PowerSync pre tournaments aplikáciu.

## Čo je PowerSync?

PowerSync je offline-first sync engine, ktorý umožňuje lokálne SQLite databázy synchronizovať s cloud backendom (Postgres, Supabase, atď.). Poskytuje:

- **Offline-first**: Aplikácia funguje aj bez internetu
- **Real-time sync**: Zmeny sa okamžite synchronizujú
- **Konfliktná resolúcia**: Automatické riešenie konfliktov pri súčasných zmenách
- **SQLite backend**: Rýchla lokálna databáza

## Migrácia - Zhrnutie

### Čo bolo urobené

1. ✅ Pridaný PowerSync Swift SDK do projektu
2. ✅ Vytvorený `PowerSyncManager` - hlavný manager pre databázu
3. ✅ Vytvorené nové modely v `PowerSyncModels.swift`:
   - `PlayerModel`
   - `TournamentModel`
   - `TournamentMatchModel`
   - `TournamentSettingsModel`
   - `TournamentTableModel`
   - `F1RaceModel`
   - `F1TeamTableModel`
   - `F1PlayerTableModel`
   - `AppUserModel`
4. ✅ Vytvorený `PowerSyncRepository` s CRUD operáciami

### Čo treba ešte urobiť

1. **Nastaviť backend** (Supabase alebo vlastný Postgres)
2. **Vytvoriť backend connector** (príklad nižšie)
3. **Migrovať ViewModely** na nové API
4. **Vytvoriť migračný skript** pre existujúce dáta z Realm
5. **Otestovať** celú integráciu

## Backend Setup

PowerSync vyžaduje backend databázu pre synchronizáciu. Máte dve možnosti:

### Možnosť 1: Supabase (Odporúčané)

1. Vytvorte si Supabase projekt na [https://supabase.com](https://supabase.com)
2. V Supabase SQL editore vytvorte schémy:

```sql
-- Players table
CREATE TABLE players (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    team TEXT,
    photo_data TEXT
);

-- Tournaments table
CREATE TABLE tournaments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner TEXT NOT NULL,
    sport TEXT NOT NULL,
    type TEXT NOT NULL,
    group_number INTEGER,
    number_of_advance_players INTEGER,
    number_of_groups INTEGER,
    playoff_matches INTEGER,
    number_of_races INTEGER,
    ripose_final INTEGER,
    ripose_knockout INTEGER,
    ripose_matches INTEGER,
    email TEXT,
    created_date INTEGER NOT NULL
);

-- Tournament Matches table
CREATE TABLE tournament_matches (
    id TEXT PRIMARY KEY,
    tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player1_id TEXT REFERENCES players(id),
    player2_id TEXT REFERENCES players(id),
    player1_score INTEGER DEFAULT 0,
    player2_score INTEGER DEFAULT 0,
    player1_score_rematch INTEGER DEFAULT 0,
    player2_score_rematch INTEGER DEFAULT 0,
    sets_string TEXT,
    fixtures_round INTEGER DEFAULT 0,
    match_date INTEGER NOT NULL,
    match_index INTEGER DEFAULT 0,
    group_index INTEGER DEFAULT 0,
    rematch_flag INTEGER DEFAULT 0
);

-- Tournament Settings table
CREATE TABLE tournament_settings (
    id TEXT PRIMARY KEY,
    tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    win_points INTEGER DEFAULT 3,
    lose_points INTEGER DEFAULT 0,
    draw_points INTEGER DEFAULT 1
);

-- Tournament Table (standings) table
CREATE TABLE tournament_table (
    id TEXT PRIMARY KEY,
    tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id TEXT NOT NULL REFERENCES players(id),
    points INTEGER DEFAULT 0,
    goals_scored INTEGER DEFAULT 0,
    goals_conceded INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    group_index INTEGER DEFAULT 0
);

-- F1 Races table
CREATE TABLE f1_races (
    id TEXT PRIMARY KEY,
    tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id TEXT REFERENCES players(id),
    name TEXT NOT NULL,
    country TEXT NOT NULL,
    laps INTEGER NOT NULL,
    date INTEGER NOT NULL,
    position INTEGER,
    start_position INTEGER NOT NULL,
    fastest_lap TEXT NOT NULL,
    pit_stops INTEGER NOT NULL,
    finished TEXT NOT NULL,
    race_number INTEGER DEFAULT 0
);

-- F1 Team Table table
CREATE TABLE f1_team_table (
    id TEXT PRIMARY KEY,
    tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    team_name TEXT NOT NULL,
    total_points INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    fastest_laps INTEGER DEFAULT 0,
    podiums INTEGER DEFAULT 0
);

-- F1 Player Table table
CREATE TABLE f1_player_table (
    id TEXT PRIMARY KEY,
    tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id TEXT NOT NULL REFERENCES players(id),
    total_points INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    fastest_laps INTEGER DEFAULT 0,
    podiums INTEGER DEFAULT 0
);

-- App Users table
CREATE TABLE app_users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

-- Create indexes for better performance
CREATE INDEX idx_tournaments_owner ON tournaments(owner);
CREATE INDEX idx_matches_tournament ON tournament_matches(tournament_id);
CREATE INDEX idx_table_tournament ON tournament_table(tournament_id);
CREATE INDEX idx_settings_tournament ON tournament_settings(tournament_id);
CREATE INDEX idx_races_tournament ON f1_races(tournament_id);
CREATE INDEX idx_team_table_tournament ON f1_team_table(tournament_id);
CREATE INDEX idx_player_table_tournament ON f1_player_table(tournament_id);
```

3. V Supabase nastavte PowerSync:
   - Zapnite Realtime pre všetky tabuľky
   - Nastavte Row Level Security (RLS) policies podľa potreby

### Možnosť 2: Vlastný Postgres Backend

Nainštalujte PostgreSQL a vytvorte rovnaké schémy ako vyššie. Potom budete potrebovať PowerSync backend service - pozrite [PowerSync dokumentáciu](https://docs.powersync.com).

## Backend Connector Implementácia

Vytvorte nový súbor `SupabaseConnector.swift`:

```swift
import Foundation
import PowerSync
import Supabase

class SupabaseConnector: PowerSyncBackendConnector {
    private let supabaseClient: SupabaseClient

    init(url: String, anonKey: String) {
        self.supabaseClient = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
    }

    func fetchCredentials() async throws -> PowerSyncCredentials {
        // Získajte access token z Supabase auth
        let session = try await supabaseClient.auth.session

        return PowerSyncCredentials(
            endpoint: "YOUR_POWERSYNC_ENDPOINT",  // z PowerSync dashboard
            token: session.accessToken
        )
    }

    func uploadData(database: PowerSyncDatabase) async throws {
        // Upload lokálnych zmien na backend
        let transaction = database.getNextCrudTransaction()

        guard let transaction = transaction else {
            return
        }

        for operation in transaction.crud {
            switch operation.op {
            case .INSERT, .UPDATE:
                try await uploadRow(table: operation.table, data: operation.opData ?? [:])
            case .DELETE:
                try await deleteRow(table: operation.table, id: operation.id)
            default:
                break
            }
        }

        // Mark transaction as uploaded
        try await transaction.complete()
    }

    private func uploadRow(table: String, data: [String: Any]) async throws {
        _ = try await supabaseClient
            .from(table)
            .upsert(data)
            .execute()
    }

    private func deleteRow(table: String, id: String) async throws {
        _ = try await supabaseClient
            .from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
```

## Inicializácia PowerSync v App

V `tournamentsApp.swift` aktualizujte:

```swift
import SwiftUI
import PowerSync

@main
struct tournamentsApp: App {
    @StateObject private var powerSyncManager = PowerSyncManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    do {
                        // Initialize PowerSync
                        try await powerSyncManager.initialize()

                        // Connect to backend
                        let connector = SupabaseConnector(
                            url: "YOUR_SUPABASE_URL",
                            anonKey: "YOUR_SUPABASE_ANON_KEY"
                        )

                        try await powerSyncManager.database?.connect(connector: connector)

                    } catch {
                        print("Failed to initialize PowerSync: \\(error)")
                    }
                }
        }
    }
}
```

## Použitie v ViewModels

Príklad migrácie `MainPageViewModel`:

```swift
import SwiftUI
import Combine

class MainPageViewModel: ObservableObject {
    @Published var tournaments: [TournamentModel] = []

    private let repository = PowerSyncRepository()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Watch tournaments reactively
        repository.watchTournaments()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error: \\(error)")
                }
            } receiveValue: { [weak self] tournaments in
                self?.tournaments = tournaments
            }
            .store(in: &cancellables)
    }

    func createTournament(name: String, sport: String, type: String, owner: String) async {
        let tournament = TournamentModel(
            name: name,
            owner: owner,
            sport: sport,
            type: type
        )

        do {
            try await repository.createTournament(tournament)
        } catch {
            print("Failed to create tournament: \\(error)")
        }
    }

    func deleteTournament(id: String) async {
        do {
            try await repository.deleteTournamentData(tournamentId: id)
        } catch {
            print("Failed to delete tournament: \\(error)")
        }
    }
}
```

## Migrácia Dát z Realm

Pre migráciu existujúcich dát z Realm do PowerSync:

1. Export dát z Realm do JSON
2. Import dát do Postgres/Supabase
3. Alebo použite migračný script, ktorý načíta z Realm a vloží do PowerSync

Príklad migračného scriptu bude v samostatnom súbore.

## Výhody PowerSync vs Realm

| Feature | Realm | PowerSync |
|---------|-------|-----------|
| Offline-first | ✅ | ✅ |
| Real-time sync | ✅ | ✅ |
| Backend | MongoDB | Postgres/Supabase/vlastný |
| SQL queries | ❌ | ✅ |
| Open source | Čiastočne | ✅ |
| Granular control | Obmedzený | Plný |
| Backend flexibility | Len MongoDB Atlas | Akýkoľvek Postgres |

## Zdroje

- [PowerSync Swift SDK Dokumentácia](https://docs.powersync.com/client-sdk-references/swift)
- [PowerSync GitHub](https://github.com/powersync-ja/powersync-swift)
- [Supabase](https://supabase.com)
- [PowerSync Blog](https://www.powersync.com/blog)

## Podpora

Pre otázky a problémy:
- PowerSync Discord: https://discord.gg/powersync
- GitHub Issues: https://github.com/powersync-ja/powersync-swift/issues
