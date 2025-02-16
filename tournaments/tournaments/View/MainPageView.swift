// Created by: Lukas Sarocky
//  MainPageView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import SwiftUI
import RealmSwift

struct MainPageView: View {
    @ObservedObject var viewModel = MainPageViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
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
            .navigationBarTitle("Tournaments")
            .onAppear {
                viewModel.loadTournaments()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private func destinationView(for tournament: Tournament) -> some View {
        switch tournament.type {
        case "Round Robin":
            RoundRobinView(viewModel: TournamentGenerateModel(tournament: tournament))
            
        case "Single Elimination", "Double Elimination", "Playoff":
            SingleEliminationView(viewModel: TournamentGenerateModel(tournament: tournament))
            
        case "Group Stage and KO":
            GSKOView(viewModel: TournamentGenerateModel(tournament: tournament),
                     gskoVM: GSKOViewModel(viewModel: TournamentGenerateModel(tournament: tournament)),
                     numberOfGroups: 4)
            
        default:
            Text("Unsupported tournament type")
        }
    }
    
}


#Preview {
    MainPageView()
}
