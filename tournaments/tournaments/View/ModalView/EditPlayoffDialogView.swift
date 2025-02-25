//
//  EditPlayoffDialogView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 23.02.2025.
//

import SwiftUI

struct EditPlayoffDialogView: View {
    var match: TournamentMatch
    @Binding var isPresented: Bool
    // Aktuálny stav série – môžete ich získať zo svojho view modelu, tu ako vstupné hodnoty:
    @State var seriesScorePlayer1: Int = 0
    @State var seriesScorePlayer2: Int = 0
    
    // Vstupné textové polia pre výsledok aktuálneho zápasu
    @State private var player1Score: String = ""
    @State private var player2Score: String = ""
    
    @State private var matchString: String = ""
    
    // Celkový počet zápasov v sérii (napr. 3, 5, 7) – určuje aj výherný práh
    var playOffMatches: Int
    
    // Callback, ktorý po uložení odošle:
    // match, skóre zápasu, a nové hodnoty série pre hráča 1 a hráča 2.
    var onSave: (TournamentMatch, Int, Int, String, Int, Bool) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                // Horný riadok – tlačidlo pre zatvorenie
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                // Zobrazenie aktuálneho stavu série
                Text("Series Score: \(match.player1Score) - \(match.player2Score)")
                    .font(.title2)
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
                
                // Tlačidlo pre uloženie výsledku
                Button(action: {
                    saveAction()
                }) {
                    Text("Save Score")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                // Zobrazenie informácie o víťaznom prahu série
                let threshold = (playOffMatches / 2) + 1
                Text("First to \(threshold) wins the series")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.black)
            .cornerRadius(12)
            .padding()
        }
    }
    
    private func addMatch() {
        if !player1Score.isEmpty && !player2Score.isEmpty {
            let setResult = (match.setsString ?? "") + "\(player1Score):\(player2Score)" + ";"
            matchString += setResult
        }
    }
    
    private func saveAction() {
        addMatch()
        if let score1 = Int(player1Score), let score2 = Int(player2Score) {
            var newSeriesScorePlayer1 = match.player1Score
            var newSeriesScorePlayer2 = match.player2Score
            if score1 > score2 {
                newSeriesScorePlayer1 += 1
            } else if score2 > score1 {
                newSeriesScorePlayer2 += 1
            }
            onSave(match, newSeriesScorePlayer1, newSeriesScorePlayer2, matchString, 0, false)
            isPresented = false
        }
    }
    
}
