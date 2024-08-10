//
//  MainPageViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import Foundation
import RealmSwift

class MainPageViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = []

    private var realm: Realm?

    init() {
        realm = RealmManager.shared.realm
        loadTournaments()
    }

    func loadTournaments() {
        guard let realm = realm else { return }
        let tournamentsResults = realm.objects(Tournament.self)
        self.tournaments = Array(tournamentsResults)
    }

    func deleteTournament(tournament: Tournament) {
        guard let realm = realm else { return }
        try? realm.write {
            realm.delete(tournament.matches)
            realm.delete(tournament.table)
            realm.delete(tournament.players)
            realm.delete(tournament.settings)
            realm.delete(tournament)
        }
        loadTournaments()
    }
}

