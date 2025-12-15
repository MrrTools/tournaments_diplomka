# Realm + MongoDB Hybrid Riešenie

Hybridná architektúra používajúca **Realm pre lokálnu databázu** a **MongoDB Atlas Data API** pre cloud synchronizáciu.

## Prečo toto riešenie?

- ✅ **Realm lokálne** - rýchla offline databáza
- ✅ **MongoDB v cloude** - zdieľanie dát medzi zariadeniami
- ✅ **Bez Realm Sync** - funguje bez deprecated Realm Sync
- ✅ **Vlastná kontrola** - úplná kontrola nad synchronizáciou
- ✅ **Obojsmerná sync** - upload aj download dát

## Architektúra

```
┌─────────────┐
│   iOS App   │
└──────┬──────┘
       │
       ├─────► Realm (lokálne)
       │       - Rýchle čítanie/zápis
       │       - Offline-first
       │
       └─────► MongoDBSyncService
               ├─► Upload (Realm → MongoDB)
               └─► Download (MongoDB → Realm)
                   │
                   ▼
           ┌───────────────────┐
           │  MongoDB Atlas    │
           │   (Cloud)         │
           └───────────────────┘
```

## 1. Nastavenie MongoDB Atlas

### Krok 1: Vytvorte MongoDB Atlas účet
1. Choďte na [https://www.mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Vytvorte si free tier cluster
3. Nastavte "Database Access" - vytvorte databázového užívateľa
4. Nastavte "Network Access" - povoľte prístup z vašich IP adries

### Krok 2: Povoľte Data API
1. V MongoDB Atlas dashboarde choďte do **Data API**
2. Kliknite na **Enable Data API**
3. Skopírujte si:
   - **Data API URL** (napr. `https://data.mongodb-api.com/app/<app-id>/endpoint/data/v1`)
   - **API Key** (vytvorte nový API key)

### Krok 3: Vytvorte databázu a collections
V Atlas UI vytvorte databázu `tournaments_db` s týmito collections:
- `players`
- `tournaments`
- `tournament_matches`
- `tournament_settings`
- `tournament_table`
- `f1_races`
- `f1_team_table`
- `f1_player_table`
- `app_users`

## 2. Konfigurácia v iOS App

### Inicializácia v `AppDelegate` alebo `App`

```swift
import SwiftUI

@main
struct TournamentsApp: App {
    @StateObject private var realmManager = RealmWithMongoDBManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // 1. Inicializujte Realm
                    await realmManager.initialize()

                    // 2. Nakonfigurujte MongoDB sync
                    realmManager.configureMongoDBSync(
                        dataAPIURL: "https://data.mongodb-api.com/app/YOUR-APP-ID/endpoint/data/v1",
                        apiKey: "YOUR-API-KEY",
                        database: "tournaments_db",
                        cluster: "Cluster0"
                    )
                }
        }
    }
}
```

### Bezpečné uloženie credentials

**DÔLEŽITÉ**: Nikdy neukladajte API keys priamo do kódu!

Použite jeden z týchto prístupov:

#### Možnosť A: Environment Variables (Xcode)
1. V Xcode: Edit Scheme → Run → Arguments → Environment Variables
2. Pridajte:
   - `MONGODB_API_URL`
   - `MONGODB_API_KEY`

```swift
let apiURL = ProcessInfo.processInfo.environment["MONGODB_API_URL"] ?? ""
let apiKey = ProcessInfo.processInfo.environment["MONGODB_API_KEY"] ?? ""
```

#### Možnosť B: Keychain
```swift
import Security

func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    SecItemAdd(query as CFDictionary, nil)
}

func getFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecSuccess,
       let data = result as? Data,
       let value = String(data: data, encoding: .utf8) {
        return value
    }
    return nil
}
```

## 3. Použitie v kóde

### Pri prihlásení používateľa - Download z MongoDB

```swift
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    private let realmManager = RealmWithMongoDBManager.shared

    func login(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Validujte používateľa (váš auth logic)
            // ...

            // 2. Stiahnite dáta z MongoDB do lokálneho Realm
            try await realmManager.syncFromMongoDBOnLogin(userEmail: email)

            print("Login successful, data synced!")
        } catch {
            print("Login failed: \(error)")
        }
    }
}
```

### Vytvorenie turnaja - Zápis do Realm + Upload do MongoDB

```swift
class NewTournamentViewModel: ObservableObject {
    private let realmManager = RealmWithMongoDBManager.shared

    func createTournament(name: String, sport: String, type: String, owner: String) async {
        let tournament = Tournament()
        tournament.name = name
        tournament.owner = owner
        tournament.sport = sport
        tournament.type = type

        do {
            // Zapíše do Realm a automaticky uploadne do MongoDB
            try await realmManager.createTournament(tournament, syncToMongoDB: true)
            print("Tournament created and synced!")
        } catch {
            print("Failed to create tournament: \(error)")
        }
    }
}
```

### Načítanie turnajov - Čítanie z lokálneho Realm

```swift
class MainPageViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = []
    private let realmManager = RealmWithMongoDBManager.shared

    init() {
        loadTournaments()
    }

    func loadTournaments() {
        // Načíta z lokálnej Realm databázy (rýchle, offline)
        if let results = realmManager.fetchAllTournaments() {
            self.tournaments = Array(results)
        }
    }
}
```

### Aktualizácia zápasu - Zápis do Realm + Upload do MongoDB

```swift
class MatchViewModel: ObservableObject {
    private let realmManager = RealmWithMongoDBManager.shared

    func updateMatchScore(match: TournamentMatch, player1Score: Int, player2Score: Int) async {
        guard let realm = realmManager.realm else { return }

        do {
            // Update v Realm
            try realm.write {
                match.player1Score = player1Score
                match.player2Score = player2Score
            }

            // Sync do MongoDB
            try await realmManager.updateMatch(match, syncToMongoDB: true)
            print("Match updated and synced!")
        } catch {
            print("Failed to update match: \(error)")
        }
    }
}
```

## 4. Synchronizačné stratégie

### Stratégia A: Sync pri prihlásení + Manual sync
```swift
// Pri prihlásení
try await realmManager.syncFromMongoDBOnLogin(userEmail: email)

// Manuálny upload všetkých zmien
try await realmManager.syncAllToMongoDB()
```

### Stratégia B: Auto-sync každých 5 minút
```swift
// V App inicializácii
realmManager.enableAutoSync(interval: 300) // 300 sekúnd = 5 minút
```

### Stratégia C: Sync po každej zmene
```swift
// Pri každej operácii nastavte syncToMongoDB: true
try await realmManager.createTournament(tournament, syncToMongoDB: true)
```

## 5. Offline režim

### Keď je zariadenie offline:
1. **Všetky operácie fungujú** - zapisujú sa do lokálnej Realm
2. **Sync do MongoDB zlyhá** - ale dáta sú uložené lokálne
3. **Pri obnovení spojenia** - zavolajte manual sync:

```swift
if NetworkMonitor.isConnected {
    try await realmManager.syncAllToMongoDB()
}
```

### Monitoring network stavu:
```swift
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    @Published var isConnected = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}
```

## 6. Handling konfliktov

Aktuálne riešenie používa **"last write wins"** stratégiu:
- MongoDB Atlas Data API `upsert` prepíše dokument najnovšou verziou
- Realm `add(update: .modified)` prepíše lokálny objekt

### Budúce vylepšenia:
Môžete pridať:
- **Timestamp porovnávanie** - uchová novší záznam
- **Verzionovanie** - sledujte verzie dokumentov
- **Konfliktné řešení UI** - nechajte používateľa vybrať

## 7. Bezpečnosť

### MongoDB Atlas API Key Security:
1. **Obmedzte permisie** - dajte API key len read/write, nie admin
2. **IP Whitelisting** - obmedzte prístup len z vašich IP adries
3. **Keychain storage** - uložte API key do iOS Keychain
4. **Revokujte staré keys** - pravidelne rotujte API keys

### Príklad RLS (Row-Level Security):
Pridajte vlastníka do každého dokumentu a filtujte pri query:

```swift
// Pri download filtrujte len dáta tohto používateľa
let filter = ["owner": currentUserEmail]
```

## 8. Migrácia z Realm Sync na túto architektúru

Ak už používate Realm Sync a chcete migrovať:

1. **Vypnite Realm Sync** v existujúcej app
2. **Nakonfigurujte MongoDB Data API**
3. **Exportujte existujúce dáta** z Realm Cloud do MongoDB Atlas
4. **Update app code** na použitie `RealmWithMongoDBManager`
5. **Prvý login** - stiahne dáta z MongoDB do lokálneho Realm

## 9. Troubleshooting

### Error: "MongoDB Data API nie je nakonfigurované"
```swift
// Uistite sa, že ste zavolali configure pred prvým použitím
realmManager.configureMongoDBSync(dataAPIURL: "...", apiKey: "...")
```

### Error: "Failed to sync: 401 Unauthorized"
- Skontrolujte API key
- Overte že API key má správne permisie v MongoDB Atlas

### Error: "Failed to sync: Network timeout"
- Skontrolujte internet pripojenie
- Overte že MongoDB Atlas cluster je running

### Dáta sa nesynchronizujú
```swift
// Skontrolujte syncToMongoDB parameter
try await realmManager.createTournament(tournament, syncToMongoDB: true) // ✅
try await realmManager.createTournament(tournament, syncToMongoDB: false) // ❌ nebude sync
```

## 10. Testovanie

### Unit testy
```swift
class MongoDBSyncTests: XCTestCase {
    func testUploadTournament() async throws {
        let manager = RealmWithMongoDBManager.shared
        await manager.initialize()

        manager.configureMongoDBSync(
            dataAPIURL: "TEST_URL",
            apiKey: "TEST_KEY"
        )

        let tournament = Tournament()
        tournament.name = "Test Tournament"

        try await manager.createTournament(tournament, syncToMongoDB: true)

        // Overte že tournament je v Realm
        let tournaments = manager.fetchAllTournaments()
        XCTAssertEqual(tournaments?.count, 1)
    }
}
```

## Zhrnutie

### Výhody tohto riešenia:
✅ Funguje offline
✅ Rýchle lokálne operácie (Realm)
✅ Cloud backup (MongoDB)
✅ Bez dependency na deprecated Realm Sync
✅ Úplná kontrola nad synchronizáciou
✅ Funguje s existujúcimi Realm modelmi

### Nevýhody:
❌ Musíte spravovať sync manuálne
❌ Nie automatická konfliktná resolúcia
❌ Potrebujete MongoDB Atlas účet

---

**Ďalšie kroky:**
1. Nastavte MongoDB Atlas cluster
2. Nakonfigurujte credentials vo vašej app
3. Implementujte login s download sync
4. Testujte offline/online scenáre
