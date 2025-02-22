//
//  F1View.swift
//  tournaments
//
//  Created by Lukas Sarocky on 21.02.2025.
//

import SwiftUI

struct F1View: View {
    @ObservedObject var viewModel: F1ViewModel
    @State var showRaceDialog = false
    @State private var selectedRaces: Int?
    
    var body: some View {
        VStack {
            ZStack {
                Text(viewModel.tournament.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
            }
            TabView {
                PlayerStandingsView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "list.number")
                        Text("Player Table")
                        
                    }
                
                TeamStandingsView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "list.number")
                        Text("Team Table")
                        
                    }
                
                RaceResultsView(viewModel: viewModel, showRaceDialog: $showRaceDialog, selectedRaces: $selectedRaces, table: viewModel.races)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Races")
                            .foregroundColor(.purple)
                    }
            }
            .frame(height: 500)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: Binding(            get: { showRaceDialog },
                                                set: { showRaceDialog = $0 }
                                   ))
        {
            if let race = selectedRaces {
                F1RaceDialogView(race: race, viewModel: viewModel, isPresented: $showRaceDialog, selectedRaceNumber: selectedRaces ?? 1)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
        }
    }
    
    struct PlayerStandingsView: View {
        @ObservedObject var viewModel: F1ViewModel
        
        var sortedTableP: [F1PlayerTable] {
            return viewModel.playerStandings.sorted {
                if $0.totalPoints != $1.totalPoints {
                    return $0.totalPoints > $1.totalPoints
                } else if $0.wins != $1.wins {
                    return $0.wins > $1.wins
                } else {
                    return $0.fastestLaps > $1.fastestLaps
                }
            }
        }
        
        var body: some View {
            Table(sortedTableP) {
                TableColumn("Position") { entry in
                    if let index = sortedTableP.firstIndex(where: { $0._id == entry._id }) {
                        Text("\(index + 1)")
                    }
                }
                TableColumn("Player Name") { entry in
                    Text(entry.player?.name ?? "TBD")
                }
                TableColumn("Points") { entry in
                    Text("\(entry.totalPoints)")
                }
                TableColumn("Wins") { entry in
                    Text("\(entry.wins)")
                }
                TableColumn("Podiums") { entry in
                    Text("\(entry.podiums)")
                }
                TableColumn("Fastest Laps") { entry in
                    Text("\(entry.fastestLaps)")
                }
            }
            .refreshable {
                viewModel.loadStandings()
            }
        }
    }
    
    struct TeamStandingsView: View {
        @ObservedObject var viewModel: F1ViewModel
        
        var sortedTableT: [F1TeamTable] {
            return viewModel.teamStandings.sorted {
                if $0.totalPoints != $1.totalPoints {
                    return $0.totalPoints > $1.totalPoints
                } else if $0.wins != $1.wins {
                    return $0.wins > $1.wins
                } else {
                    return $0.fastestLaps > $1.fastestLaps
                }
            }
        }
        
        var body: some View {
            Table(sortedTableT) {
                TableColumn("Position") { entry in
                    if let index = sortedTableT.firstIndex(where: { $0._id == entry._id }) {
                        Text("\(index + 1)")
                    }
                }
                TableColumn("Player Name") { entry in
                    Text(entry.teamName)
                }
                TableColumn("Points") { entry in
                    Text("\(entry.totalPoints)")
                }
                TableColumn("Wins") { entry in
                    Text("\(entry.wins)")
                }
                TableColumn("Podiums") { entry in
                    Text("\(entry.podiums)")
                }
                TableColumn("Fastest Laps") { entry in
                    Text("\(entry.fastestLaps)")
                }
            }
            .refreshable {
                viewModel.loadStandings()
            }
        }
    }
}
