//
//  RoudRobinView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 29.07.2024.
//

import SwiftUI
import RealmSwift

struct RoundRobinView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @State var showScoreDialog = false
    @State private var selectedMatch: Match?
    @State private var showSettings = false

    var body: some View {
        VStack {
            ZStack {
                            Text(viewModel.tournament.name)
                                .font(.largeTitle)
                                .bold()
                                .padding(.horizontal)

                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    showSettings.toggle()  // Při kliknutí se zobrazí nastavení
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding()
                                       
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.top)
            TabView {
                LeaderboardView(table: viewModel.table, viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "list.number")
                        Text("Table")
                            
                    }

                MatchesView(viewModel: viewModel, showScoreDialog: $showScoreDialog, selectedMatch: $selectedMatch)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Matches")
                            .foregroundColor(.purple)
                    }
            }
            .frame(height: 500)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showSettings) {
            if let settings = viewModel.tournament.settings.first {
                SettingsView(settings: settings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: Binding(            get: { showScoreDialog },
                                                set: { showScoreDialog = $0 }
                                   ))
        {
            if let match = selectedMatch {
                EditModalDialogView(match: match, isPresented: $showScoreDialog, onSave: viewModel.updateMatchScore)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            
        }
    }
}

struct LeaderboardView: View {
    var table: [TournamentTable]
    @ObservedObject var viewModel: TournamentGenerateModel
    
    var sortedTable: [TournamentTable] {
        return table.sorted {
            if $0.points != $1.points {
                return $0.points > $1.points
            } else if $0.scoreDifference != $1.scoreDifference {
                return $0.scoreDifference > $1.scoreDifference
            } else if $0.goalsScored != $1.goalsScored {
                return $0.goalsScored > $1.goalsScored
            } else {
                return $0.goalsConceded < $1.goalsConceded
            }
        }
    }
    var body: some View {
        Table(sortedTable) {
            TableColumn("Position") { table in
                if let index = sortedTable.firstIndex(where: { $0._id == table._id }) {
                    Text("\(index + 1)")
                }
            }
            
            TableColumn("Player Name"){ table in
                Text(table.player?.name ?? "TBD")
            }
            TableColumn("Points") { table in
                Text("\(table.points)")
            }
            TableColumn("Score") { table in
                Text("\(table.goalsScored):\(table.goalsConceded)")
            }
            TableColumn("Wins") { table in
                Text("\(table.wins)")
            }
            TableColumn("Draws") { table in
                Text("\(table.draws)")
            }
            TableColumn("Losses") { table in
                Text("\(table.losses)")
            }
        }
        .refreshable {
            viewModel.loadTable()  // Trigger table reload on pull-to-refresh
        }
    }
}
