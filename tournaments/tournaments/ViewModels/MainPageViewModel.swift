import Foundation
import RealmSwift

class MainPageViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = []
    
    private var realm: Realm?
    private let showPublicTournaments: Bool
    private let currentUser: AppUser?

    init(showPublicTournaments: Bool) {
        self.realm = RealmManager.shared.realm
        self.showPublicTournaments = showPublicTournaments
        self.currentUser = AuthService.shared.currentUser
        loadTournaments()
    }

    func loadTournaments() {
        guard let realm = realm else { return }

        if showPublicTournaments {
            // Show only tournaments with no owner (public tournaments)
            tournaments = Array(realm.objects(Tournament.self).filter("email == nil"))
        } else if let user = currentUser {
            // Show tournaments belonging to the logged-in user
            tournaments = Array(realm.objects(Tournament.self).filter("email == %@", user.email))
        } else {
            tournaments = []
        }
    }

    func deleteTournament(tournament: Tournament) {
        guard let realm = realm else { return }
        try? realm.write {
            realm.delete(tournament.table)
            realm.delete(tournament.matches)
            realm.delete(tournament.players)
            realm.delete(tournament.settings)
            realm.delete(tournament.f1Race)
            realm.delete(tournament.f1TeamTable)
            realm.delete(tournament.f1PlayerTable)
            realm.delete(tournament)
        }
        loadTournaments()
    }
}
