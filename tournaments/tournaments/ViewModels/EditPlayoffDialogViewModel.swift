//
//  EditPlayoffDialogViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 23.02.2025.
//
import Foundation
import RealmSwift

class EditPlayoffDialogViewModel: ObservableObject {
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
            onSave(match, newSeriesScorePlayer1, newSeriesScorePlayer2, matchString, 0)
            isPresented = false
        }
    }
}
