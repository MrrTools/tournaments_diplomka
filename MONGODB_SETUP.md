# MongoDB Setup Guide

## Prehľad zmien

V tejto branch boli vykonané nasledujúce zmeny:

1. **Odstránenie MongoDB Realm Flexible Sync** - RealmManager už nepoužíva `App`, `User` a flexibleSyncConfiguration
2. **Realm ako lokálna databáza** - Realm teraz funguje výlučne ako lokálna SQLite databáza
3. **Priamy zápis do MongoDB** - Vytvorený `MongoDBManager` pre priame write operácie do MongoDB databázy

## Inštalácia MongoDB Swift Driver

### Krok 1: Pridanie balíčka v Xcode

1. Otvorte projekt `tournaments.xcodeproj` v Xcode
2. Kliknite na **File → Add Package Dependencies...**
3. V search bare zadajte URL: `https://github.com/mongodb/mongo-swift-driver`
4. Vyberte verziu **1.3.1** alebo novšiu
5. Kliknite na **Add Package**
6. Uistite sa, že balíček `MongoSwift` je pridaný do vášho target

### Krok 2: Odkomentovanie kódu v MongoDBManager.swift

Po pridaní balíčka otvorte súbor:
```
tournaments/tournaments/RealmDB/MongoDBManager.swift
```

Odkomentujte tieto sekcie:

1. **Import** (riadok ~15):
```swift
import MongoSwift
```

2. **Properties** (riadky ~24-26):
```swift
private var client: MongoClient?
private var database: MongoDatabase?
```

3. **Všetky funkcie** - Odkomentujte kompletný kód v týchto funkciách:
   - `connect()`
   - `disconnect()`
   - `insertTournament()`
   - `updateTournament()`
   - `insertMatch()`
   - `updateMatch()`
   - `insertUser()`
   - `insertF1Race()`
   - `updateTable()`
   - `deleteTournament()`

### Krok 3: Konfigurácia MongoDB pripojenia

V `MongoDBManager.swift` upravte connection string (riadok ~21):

```swift
private let connectionString = "mongodb://localhost:27017"  // Lokálne
// ALEBO pre MongoDB Atlas:
// private let connectionString = "mongodb+srv://username:password@cluster.mongodb.net"
```

Upravte názov databázy podľa potreby (riadok ~22):
```swift
private let databaseName = "tournaments_db"
```

### Krok 4: Inicializácia MongoDB pri štarte aplikácie

V hlavnom `App` súbore alebo v `ContentView` pridajte inicializáciu:

```swift
Task {
    try? await MongoDBManager.shared.connect()
}
```

## Ako to funguje

### Dual Write Pattern

Aplikácia teraz používa **dual write** pattern:

1. **Realm (lokálna databáza)** - Všetky dáta sa zapisujú do lokálnej Realm databázy
2. **MongoDB (vzdialená databáza)** - Následne sa asynchrónne zapisujú do MongoDB

Príklad z `NewTournamentViewModel.swift`:
```swift
// Zápis do Realm
try? realm.write {
    realm.add(tournament)
}

// Zápis do MongoDB (asynchrónne)
Task {
    try? await MongoDBManager.shared.insertTournament([...])
}
```

### Kde sú MongoDB write operácie

MongoDB write operácie boli pridané do týchto súborov:

- **NewTournamentViewModel.swift** - Vytvorenie nového turnaja
- **TournamentGenerateModel.swift** - Aktualizácia zápasov a tabuľky
- **F1ViewModel.swift** - Pridávanie pretekov a aktualizácia standings
- **AuthService.swift** - Registrácia nových používateľov
- **MainPageViewModel.swift** - Vymazanie turnaja

## MongoDB Kolekcie

MongoDBManager zapisuje do týchto kolekcií:

- `tournaments` - Základné info o turnajoch
- `matches` - Zápasy
- `tables` - Tabuľky standings
- `users` - Registrovaní používatelia
- `f1_races` - F1 preteky

## Testing bez MongoDB

Ak zatiaľ nemáte MongoDB server, aplikácia bude naďalej fungovať:

- Všetky dáta sa ukladajú do lokálnej Realm databázy
- MongoDB operácie sa simulujú (print statements)
- Žiadne chyby sa nezobrazujú používateľovi

## Produkčné nasadenie

Pre produkčné prostredie:

1. Nastavte MongoDB Atlas cluster
2. Vytvorte database user s read/write oprávneniami
3. Získajte connection string
4. Aktualizujte `connectionString` v `MongoDBManager.swift`
5. **DÔLEŽITÉ**: Neprihlaste connection string do git! Použite environment variables alebo secrets management

## Troubleshooting

### Build error: "No such module 'MongoSwift'"
- Uistite sa, že ste pridali balíček cez SPM
- Skúste **Product → Clean Build Folder** a znovu buildnite

### Connection timeout
- Skontrolujte MongoDB server status
- Overte connection string
- Skontrolujte firewall/network pravidlá

### Dáta sa nezapisujú do MongoDB
- Skontrolujte konzolu pre error messages
- Overte, že `MongoDBManager.shared.connect()` bol zavolaný pri štarte
- Skontrolujte MongoDB logs

## Poznámky

- Aplikácia funguje offline-first - všetky dáta sú primárne v Realm
- MongoDB je "write-only" - aplikácia z neho nečíta dáta
- Pre sync oboch databáz by bolo potrebné implementovať read operácie z MongoDB
