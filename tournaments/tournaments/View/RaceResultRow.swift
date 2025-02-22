//
//  RaceResultRow.swift
//  tournaments
//
//  Created by Lukas Sarocky on 22.02.2025.
//

import SwiftUI

struct RaceResultRow: View {
    // Jeden záznam preteku (obsahuje info o hráčovi a jeho výsledku)
    @ObservedObject var result: F1Race
    var table: [F1Race]
    
    // Referencia na view model, aby sme vedeli volať update
    @ObservedObject var viewModel: F1ViewModel
    
    // Lokálne @State premenné pre polia (String), ktoré chceme upraviť
    @State private var positionText: String
    @State private var fastestLapText: String
    @State private var pitStopsText: String

    init(result: F1Race, viewModel: F1ViewModel) {
        self.result = result
        self.viewModel = viewModel
        self.table = table

        // Pri inicializácii premeníme existujúce hodnoty na string
        _positionText = State(initialValue: result.position.map { String($0) } ?? "")
        _fastestLapText = State(initialValue: result.fastestLap)
        _pitStopsText = State(initialValue: String(result.pitStops))
    }

    var body: some View {
        HStack {
            
              Table(table) {
                  TableColumn("Position") { entry in
                      if let index = table.firstIndex(where: { $0._id == entry._id }) {
                          Text("\(index + 1)")
                      }
                  }
                  TableColumn("Player Name") { entry in
                      Text(entry.player?.name ?? "TBD")
                  }
                  TableColumn("Positions") { entry in
                      Text("\(entry.position)")
                  }
                  TableColumn("Start Position") { entry in
                      Text("\(entry.startPosition)")
                  }
                  TableColumn("Finish Position") { entry in
                      Text("\(entry.finished)")
                  }
                  TableColumn("Fastest Laps") { entry in
                      Text("\(entry.fastestLap)")
                  }
                  TableColumn("Pistops Number") { entry in
                      Text("\(entry.pitStops)")
                  }
              }
              .refreshable {
                  viewModel.loadStandings()
              }
            // Meno hráča
            Text(result.player?.name ?? "TBD")
                .frame(minWidth: 100, alignment: .leading)

            // Editable text field pre "position"
            TextField("Pos", text: $positionText)
                .keyboardType(.numberPad)
                .frame(width: 50)
                // onCommit sa volá po "enter", v iOS to býva "done" na klávesnici
                .onSubmit {
                    //saveChanges()
                }

            // Editable text field pre "fastestLap"
            TextField("Fastest Lap", text: $fastestLapText)
                .frame(width: 100)
                .onSubmit {
                    //saveChanges()
                }

            // Editable text field pre "pitStops"
            TextField("Pit stops", text: $pitStopsText)
                .keyboardType(.numberPad)
                .frame(width: 50)
                .onSubmit {
                    //saveChanges()
                }
        }
        .onDisappear {
            // Ak user odíde z tohto riadku, môžeme tiež uložiť zmeny (nepovinné)
            //saveChanges()
        }
    }

  /*  private func saveChanges() {
        // Prevedieme String -> Int
        let newPosition = Int(positionText) ?? 0
        let newPitStops = Int(pitStopsText) ?? 0
        // Zavoláme update vo ViewModeli
        viewModel.updateResult(
            result: result,
            position: newPosition,
            fastestLap: fastestLapText,
            pitStops: newPitStops
        )
    }*/
}
