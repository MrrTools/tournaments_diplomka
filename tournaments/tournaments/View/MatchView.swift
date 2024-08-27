//  MatchView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//

import SwiftUI

struct MatchesView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
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
                            .frame(minWidth: 100, alignment: .trailing)
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
