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
    @State private var selectedMatch: TournamentMatch?
    @State private var showSettings = false
    @State private var rematchFlag = 0
    @State private var koFlag = 0
    
    var body: some View {
        ZStack {
            // Background image
            if let backgroundImageData = viewModel.tournament.backgroundImageData,
               let uiImage = UIImage(data: backgroundImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.3)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }

            // Content
            VStack {
                ZStack {
                    Text(viewModel.tournament.name)
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)

                    HStack {
                        Spacer()

                        Button(action: {
                            showSettings.toggle()
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
                    LeaderBoardView(table: viewModel.table, viewModel: viewModel)
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
        }
        .sheet(isPresented: Binding(            get: { showSettings },
                                                set: { showSettings = $0 }
                                   ))
        {
            if let settings = viewModel.tournament.settings.first {
                SettingsView(settings: settings, isPresented: $showSettings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: Binding(            get: { showScoreDialog },
                                                set: { showScoreDialog = $0 }
                                   ))
        {
            if let match = selectedMatch {
                EditModalDialogView(match: match, isPresented: $showScoreDialog, rematchFlag: rematchFlag, koFlag: (koFlag != 0), onSave: viewModel.updateMatchScore)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            
        }
    } 
}
