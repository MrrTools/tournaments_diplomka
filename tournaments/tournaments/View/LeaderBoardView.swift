//
//  LeaderBoardView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 10.02.2025.
//

import SwiftUI

struct LeaderBoardView: View {
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
            TableColumn("Position") { entry in
                if let index = sortedTable.firstIndex(where: { $0._id == entry._id }) {
                    Text("\(index + 1)")
                }
            }
            TableColumn("Player Name") { entry in
                Text(entry.player?.name ?? "TBD")
            }
            TableColumn("Points") { entry in
                Text("\(entry.points)")
            }
            TableColumn("Score") { entry in
                Text("\(entry.goalsScored):\(entry.goalsConceded)")
            }
            TableColumn("Wins") { entry in
                Text("\(entry.wins)")
            }
            TableColumn("Draws") { entry in
                Text("\(entry.draws)")
            }
            TableColumn("Losses") { entry in
                Text("\(entry.losses)")
            }
        }
        .refreshable {
            viewModel.loadTable()
        }
    }
}
