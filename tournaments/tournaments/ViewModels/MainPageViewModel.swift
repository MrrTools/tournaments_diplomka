import Foundation
import RealmSwift
import SwiftUI
import Combine

class MainPageViewModel: ObservableObject {
    @Published var tournaments: [Tournament] = []
    
    private var realm: Realm?
    private let showPublicTournaments: Bool
    private var cancellables = Set<AnyCancellable>()
    
    init(showPublicTournaments: Bool) {
        self.realm = RealmManager.shared.realm
        self.showPublicTournaments = showPublicTournaments
        
        // Načítame turnaje pri inicializácii
        loadTournaments()
        
        // Sledujeme zmeny v currentUser
        AuthService.shared.$currentUser
            .sink { [weak self] _ in
                self?.loadTournaments()
            }
            .store(in: &cancellables)
    }
    
    func loadTournaments() {
        guard let realm = realm else { return }
        
        let currentUser = AuthService.shared.currentUser
        
        switch (showPublicTournaments, currentUser) {
        case (true, _):
            tournaments = Array(realm.objects(Tournament.self)
                .filter("email == nil"))
            
        case (false, let user?) where user.email != "":
            tournaments = Array(realm.objects(Tournament.self)
                .filter("email == %@", user.email))
            
        default:
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
    
    @ViewBuilder
    func destinationView(for tournament: Tournament) -> some View {
        let tournamentModel = TournamentGenerateModel(tournament: tournament)
        
        switch tournament.type {
        case "Round Robin":
            RoundRobinView(viewModel: tournamentModel)
            
        case "Single Elimination", "Double Elimination", "Playoff":
            SingleEliminationView(viewModel: tournamentModel)
            
        case "Group Stage and KO":
            GSKOView(gskoVM: GSKOViewModel(viewModel: tournamentModel), viewModel: tournamentModel, numberOfGroups: tournament.numberOfGroups ?? 4)
            
        case "Championship":
            F1View(viewModel: F1ViewModel(tournament: tournament))
            
        default:
            Text("Unsupported tournament type")
        }
    }
}
