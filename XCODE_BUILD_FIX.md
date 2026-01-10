# Xcode Build Fix - iOS Minimum Version Error

## Problém
```
The package product 'SwiftBSON' requires minimum platform version 13.0 for the iOS platform,
but this target supports 12.0
```

## Riešenie

Projekt už má správne nastavenú iOS verziu (17.6), ale Xcode/SPM má staré cache. Nasledujte tieto kroky:

### 1. Vyčistite Derived Data

V Xcode:
```
Product → Clean Build Folder (Shift + Cmd + K)
```

Potom:
```
File → Workspace Settings → Derived Data → Delete...
```

Alebo príkazom:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 2. Reset Swift Package Manager Cache

V Xcode:
```
File → Packages → Reset Package Caches
```

### 3. Aktualizujte Swift Package Dependencies

```
File → Packages → Update to Latest Package Versions
```

### 4. Reštartujte Xcode

Zatvorte Xcode úplne a otvorte znovu.

### 5. Build projekt znovu

```
Product → Build (Cmd + B)
```

## Alternatívne riešenie - Manuálna úprava Package.resolved

Ak vyššie kroky nepomôžu:

1. Zatvorte Xcode
2. Vymažte súbor `tournaments.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
3. Otvorte Xcode
4. Xcode automaticky znovu stiahne všetky dependencies s správnymi verziami

## Overenie nastavení projektu

V Xcode:

1. Vyberte projekt "tournaments" v Project Navigator
2. Vyberte target "tournaments"
3. Prejdite na tab "General"
4. Overte "Minimum Deployments" → "iOS" je nastavené na **13.0 alebo vyššie**

Aktuálne by malo byť nastavené na: **17.6**

## Ak stále nefunguje

Skúste odstrániť a znovu pridať MongoDB Swift Driver:

1. V Xcode: File → Packages
2. Nájdite "mongo-swift-driver"
3. Kliknite pravým tlačidlom → Remove Package
4. File → Add Package Dependencies
5. URL: `https://github.com/mongodb/mongo-swift-driver`
6. Vyberte "main" branch (alebo verziu 1.3.1+)
7. Add Package

## Poznámka

Tento problém je známy bug v Xcode/SPM cache systéme, kde si pamätá staré nastavenia aj keď projekt má správne hodnoty.
