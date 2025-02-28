//  MainPageView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.

import SwiftUI
import RealmSwift

struct MainPageView: View {
    @ObservedObject var viewModel: MainPageViewModel
    @State private var navigateToLogin = false
    let showPublicTournaments: Bool

    init(showPublicTournaments: Bool = false) {
        self.showPublicTournaments = showPublicTournaments
        self.viewModel = MainPageViewModel(showPublicTournaments: showPublicTournaments)
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    
                    Text("Tournaments")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()

                    Button(action: {
                        AuthService.shared.logout()
                        navigateToLogin = true
                    }) {
                        Image(systemName: "power")
                            .font(.title2)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                HStack {
                    Spacer()
                    NavigationLink(destination: NewTournamentView(viewModel: NewTournamentViewModel(onSave: {
                        viewModel.loadTournaments()
                    }))) {
                        Image(systemName: "plus")
                            .font(.title)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()

                List {
                    ForEach(viewModel.tournaments, id: \.id) { tournament in
                        NavigationLink(destination: destinationView(for: tournament)) {
                            VStack(alignment: .leading) {
                                Text(tournament.name)
                                    .font(.title)
                                Text(tournament.sport)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Type: \(tournament.type)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Owner: \(tournament.owner)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .cornerRadius(8)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let tournament = viewModel.tournaments[index]
                            viewModel.deleteTournament(tournament: tournament)
                        }
                    }
                }

                Spacer()
            }
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadTournaments()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for tournament: Tournament) -> some View {
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
