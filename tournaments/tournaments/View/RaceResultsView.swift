import SwiftUI

struct RaceResultsView: View {
    @ObservedObject var viewModel: F1ViewModel
    
    @State private var selectedRaceNumber = 1
    @State private var showAddRaceModal = false
    
    @Binding var showRaceDialog: Bool
    @Binding var selectedRaces: Int?
    
    // Zoznam pretekov (nestriedene) – môže byť priamo z viewModelu alebo inak
    var table: [F1Race]
    
    // Computed property: výsledok bude **vždy** zoradený podľa `position`
    var sortedTable: [F1Race] {
        table.sorted { a, b in
            let posA = a.position ?? Int.max
            let posB = b.position ?? Int.max
            return posA < posB  // vzostupné poradie
        }
    }
    
    var body: some View {
        VStack {
            // 1) Picker na výber pretekov
            Picker("Select Race", selection: $selectedRaceNumber) {
                let numberOfRaces = viewModel.tournament.numberOfRaces ?? 1
                ForEach(1...numberOfRaces, id: \.self) { raceNumber in
                    Text("Race \(raceNumber)").tag(raceNumber)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // 2) Skontrolujeme, či daný pretek existuje
            if let race = viewModel.getRace(for: selectedRaceNumber) {
                // Zobrazenie detailov pretekov
                VStack(alignment: .leading) {
                    Text(race.name).bold()
                    Text("\(race.country) - \(race.laps) laps")
                }
                .padding()
                
                // 3) Editovateľná tabuľka zobrazujúca "sortedTable"
                Table(sortedTable) {
                    
                    // Index stĺpec
                    TableColumn("Index") { entry in
                        if let index = sortedTable.firstIndex(where: { $0._id == entry._id }) {
                            Text("\(index + 1)")
                        }
                    }
                    
                    // Player Name
                    TableColumn("Player Name") { entry in
                        Text(entry.player?.name ?? "TBD")
                    }
                    
                    // Edit: Position
                    TableColumn("Position") { entry in
                        TextField(
                            "",
                            text: Binding(
                                get: {
                                    // Position je Int?, prevedieme na String
                                    entry.position.map(String.init) ?? ""
                                },
                                set: { newValue in
                                    // Pri zmene textu konvertujeme späť na Int
                                    let newPos = Int(newValue) ?? (entry.position ?? 0)
                                    // Uložíme do DB
                                    viewModel.updateRace(entry, position: newPos)
                                    viewModel.loadRaces()
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .keyboardType(.numberPad)
                    }
                    
                    // Start Position
                    TableColumn("Start Position") { entry in
                        TextField(
                            "",
                            text: Binding(
                                get: { String(entry.startPosition) },
                                set: { newValue in
                                    let newStartPos = Int(newValue) ?? entry.startPosition
                                    viewModel.updateRace(entry, startPosition: newStartPos)
                                    viewModel.loadRaces()
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .keyboardType(.numberPad)
                    }
                    
                    // Finish Position
                    TableColumn("Finish Position") { entry in
                        TextField(
                            "",
                            text: Binding(
                                get: { entry.finished },
                                set: { newValue in
                                    viewModel.updateRace(entry, finished: newValue)
                                    viewModel.loadRaces()
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .keyboardType(.numberPad)
                    }
                    
                    // Fastest Lap
                    TableColumn("Fastest Lap") { entry in
                        TextField(
                            "",
                            text: Binding(
                                get: { entry.fastestLap },
                                set: { newValue in
                                    viewModel.updateRace(entry, fastestLap: newValue)
                                    viewModel.loadRaces()
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    }
                    
                    // Pitstops
                    TableColumn("Pitstops Number") { entry in
                        TextField(
                            "",
                            text: Binding(
                                get: { String(entry.pitStops) },
                                set: { newValue in
                                    let newStops = Int(newValue) ?? entry.pitStops
                                    viewModel.updateRace(entry, pitStops: newStops)
                                    viewModel.loadRaces()
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                    }
                }
                // Povolené potiahnutie pre refresh
                .refreshable {
                    viewModel.loadStandings()
                }
                
            } else {
                Spacer()
                // 4) Ak pretek neexistuje, ponúkni tlačidlo "+"
                Button(action: {
                    selectedRaces = selectedRaceNumber
                    showRaceDialog = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.purple)
                        .clipShape(Circle())
                }
            }
        }
    }
}
