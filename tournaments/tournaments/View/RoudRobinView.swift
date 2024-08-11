//
//  RoudRobinView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 29.07.2024.
//

import SwiftUI
import RealmSwift

struct RoundRobinView: View {
    @ObservedObject var viewModel: RoundRobinViewModel
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
                ScoreInputDialog(match: match, isPresented: $showScoreDialog, onSave: viewModel.updateMatchScore)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            
        }
    }
}

struct LeaderboardView: View {
    var table: [TournamentTable]
    @ObservedObject var viewModel: RoundRobinViewModel
    
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

struct MatchesView: View {
    @ObservedObject var viewModel: RoundRobinViewModel
    @Binding var showScoreDialog: Bool
    @Binding var selectedMatch: Match?

    var body: some View {
        VStack {
            Picker("Rounds", selection: $viewModel.selectedRound) {
                ForEach(1...viewModel.numberOfRounds, id: \.self) { round in
                    Text("Round \(round)").tag(round)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List {
                ForEach(viewModel.matchesForSelectedRound, id: \.id) { match in
                    HStack {
                        Text(match.player1?.name ?? "TBD")
                            .font(.headline)
                            .frame(minWidth: 100, alignment: .leading)
                        Spacer()
                        Button(action: {
                            selectedMatch = match
                            showScoreDialog = true
                        }) {
                            Text("\(match.player1Score) - \(match.player2Score)")
                                .font(.subheadline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Spacer()
                        Text(match.player2?.name ?? "TBD")
                            .font(.headline)
                            .frame(minWidth: 100, alignment: .trailing)  // Nastavení minimální šířky pro zarovnání
                    }
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
            }
            .padding(.horizontal)
        }
        .onAppear {
            print("Match")
        }
    }
}


struct ScoreInputDialog: View {
    var match: Match
    @Binding var isPresented: Bool
    @State private var player1Score: String = ""
    @State private var player2Score: String = ""
    var onSave: (Match, Int, Int) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }

                Text("Enter Score")
                    .font(.headline)
                    .padding()

                HStack {
                    VStack {
                        Text(match.player1?.name ?? "TBD")
                        if let photoData = match.player1?.photoData, let uiImage = UIImage(data: photoData) {
                             Image(uiImage: uiImage)
                                 .resizable()
                                 .frame(width: 50, height: 50)
                                 .clipShape(Circle())
                         } else {
                             Image(systemName: "person.crop.circle")
                                 .resizable()
                                 .frame(width: 50, height: 50)
                                 .foregroundColor(.gray)
                                 .clipShape(Circle())
                         }
                        TextField("-", text: $player1Score)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("VS")
                        .font(.largeTitle)
                        .padding()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack {
                        Text(match.player2?.name ?? "TBD")
                        if let photoData = match.player2?.photoData, let uiImage = UIImage(data: photoData) {
                             Image(uiImage: uiImage)
                                 .resizable()
                                 .frame(width: 50, height: 50)
                                 .clipShape(Circle())
                         } else {
                             Image(systemName: "person.crop.circle")
                                 .resizable()
                                 .frame(width: 50, height: 50)
                                 .foregroundColor(.gray)
                                 .clipShape(Circle())
                         }
                        TextField("-", text: $player2Score)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()

                DatePicker("Date", selection: .constant(Date()), displayedComponents: .date)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    if let p1Score = Int(player1Score), let p2Score = Int(player2Score) {
                        onSave(match, p1Score, p2Score)
                        isPresented = false
                    }
                }) {
                    Text("Update")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .padding()
            .background(Color.black)
            .cornerRadius(8)
            .shadow(radius: 20)
        }
    }
}
