//  MatchView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 15.07.2024.
//

import SwiftUI

struct MatchesView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @Binding var showScoreDialog: Bool
    @Binding var selectedMatch: TournamentMatch?
    
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
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            selectedMatch = match
                            showScoreDialog = true
                        }) {
                            HStack(spacing: 8) {
                                // Indikátor pre prvý zápas
                                Image(systemName: match.isPlayed ? "checkmark.square.fill" : "square")
                                    .foregroundColor(match.isPlayed ? .purple : .gray)
                                
                                Text("\(match.player1Score) - \(match.player2Score)")
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(match.isPlayed ? Color.purple.opacity(0.3) : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()
                        Text(match.player2?.name ?? "TBD")
                            .font(.headline)
                            .frame(minWidth: 100, alignment: .trailing)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 5)
                    .background(match.isPlayed ? Color.purple.opacity(0.15) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
            }
            .padding(.horizontal)
        }
        .onAppear {
            print("Match View for Group")
        }
    }
}
