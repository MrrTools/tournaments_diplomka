//
//  SingleEliminationView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 29.07.2024.
//

import SwiftUI
import Foundation
import RealmSwift

class SingleEliminationViewModel: ObservableObject {
    @Published var tournament: Tournament
    @Published var matches: List<Match> = List<Match>()

    init(tournament: Tournament) {
        self.tournament = tournament
        self.loadMatches()
    }

    func loadMatches() {
        let realm = try! Realm()
        let matches = realm.objects(Match.self).filter("tournament == %@", tournament)
        self.matches.append(objectsIn: matches)
    }

    func createBracket(from players: [Player]) -> [[(Player?, Player?)]]? {
        guard players.count > 1 else { return nil }

        var rounds: [[(Player?, Player?)]] = []
        var currentRound: [(Player?, Player?)] = players.chunked(into: 2).map { ($0.first, $0.last) }

        while currentRound.count > 1 {
            rounds.append(currentRound)
            currentRound = currentRound.chunked(into: 2).map { ($0.first?.0, $0.last?.1) }
        }

        rounds.append(currentRound)
        return rounds
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        for index in stride(from: 0, to count, by: size) {
            let chunk = Array(self[index..<Swift.min(index + size, count)])
            chunks.append(chunk)
        }
        return chunks
    }
}


#Preview {
    SingleEliminationViewModel()
}
