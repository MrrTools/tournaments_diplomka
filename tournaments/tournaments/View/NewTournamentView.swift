import SwiftUI

struct NewTournamentView: View {
    // Vytvoření pozorovaného objektu, který bude obsahovat data pro turnaj
    @ObservedObject var viewModel: NewTournamentViewModel
    // Stavové proměnné pro správu zobrazení a interakce
    @State private var showImagePicker = false
    @State private var selectedPlayerIndex: Int? = nil
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let eliminationPlayerCounts = [2, 4, 8, 16, 32, 64]
    
    var body: some View {
        VStack {
            // Záhlaví obrazovky
            Text("Create Tournament")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Form {
                // Sekce pro zadání názvu turnaje
                Section(header: Text("Name your tournament")) {
                    TextField("Tournament Name", text: $viewModel.tournamentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Sekce pro zadání jména vlastníka turnaje
                Section(header: Text("Owner")) {
                    TextField("Owner Name", text: $viewModel.owner)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Sekce pro výběr sportu
                Section(header: Text("Select sport")) {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        Text("Select a sport").tag(String?.none)
                        ForEach(viewModel.sportTypes.keys.sorted(), id: \.self) { sport in
                            Text(sport).tag(String?.some(sport))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Podmíněná sekce pro výběr turnajového modu
                if let selectedSport = viewModel.selectedSport {
                    Section(header: Text("Tournament mod")) {
                        Picker("Tournament", selection: $viewModel.selectedType) {
                            Text("Select a Type").tag(String?.none)
                            ForEach(viewModel.sportTypes[selectedSport] ?? [], id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
                
                // Přepínač pro zahrnutí ripose zápasů, pokud je vybrán Round Robin
                if viewModel.selectedType == "Round Robin" {
                    Toggle(isOn: $viewModel.riposeMateches) {
                        Text("Include ripose Matches")
                    }
                }
                
                // Sekce pro výběr počtu hráčů
                Section(header: Text("Number of Players")) {
                    VStack {
                        if viewModel.selectedType == "Single Elimination" || viewModel.selectedType == "Double Elimination" {
                            Slider(
                                value: Binding(
                                    get: {
                                        Double(eliminationPlayerCounts.first(where: { $0 >= Int(viewModel.numberOfPlayers) }) ?? 2)
                                    },
                                    set: { newValue in
                                        viewModel.numberOfPlayers = Double(eliminationPlayerCounts.min(by: { abs($0 - Int(newValue)) < abs($1 - Int(newValue)) }) ?? 2)
                                    }
                                ),
                                in: 2...64,
                                step: 1
                            )
                            Text("Number of Players: \(Int(viewModel.numberOfPlayers))")
                                .foregroundColor(viewModel.isEditing ? .red : .purple)
                        } else {
                            Slider(
                                value: $viewModel.numberOfPlayers,
                                in: 2...64,
                                step: 1,
                                onEditingChanged: { editing in
                                    viewModel.isEditing = editing
                                }
                            )
                            Text("Number of Players: \(Int(viewModel.numberOfPlayers))")
                                .foregroundColor(viewModel.isEditing ? .red : .purple)
                        }
                    }
                }
                
                // Sekce pro zadání hráčů a jejich fotografií
                Section(header: Text("Players")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        ForEach(0..<Int(viewModel.numberOfPlayers), id: \.self) { index in
                            HStack {
                                if let image = viewModel.playerPhotos[index] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "camera")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                }
                                TextField("Player \(index + 1)", text: $viewModel.players[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                
                                Spacer()
                            }
                            .padding(.vertical)
                        }
                    }
                }
                
                // Sekce pro přidání fotografie hráče
                Section(header: Text("Add Player Photo")) {
                    HStack {
                        Picker("Select Player", selection: $selectedPlayerIndex) {
                            Text("Select a Player").tag(Int?.none)
                            ForEach(0..<Int(viewModel.numberOfPlayers), id: \.self) { index in
                                Text(viewModel.players[index].isEmpty ? "Player \(index + 1)" : viewModel.players[index])
                                    .tag(Int?.some(index))
                                    .foregroundColor(.purple)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                        
                        Button(action: {
                            if selectedPlayerIndex != nil {
                                showImagePicker = true
                            }
                        }) {
                            Text("Add Photo")
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            
            // Tlačítko pro vytvoření turnaje
            Button(action: {
                viewModel.saveTournament()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Text("Create Tournament")
                    Image(systemName: "checkmark.circle")
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.purple)
                .cornerRadius(8)
            }
            .padding()
        }
        .background(Color.black.opacity(0.9))
        .foregroundColor(.white)
        .sheet(isPresented: $showImagePicker) {
            if let selectedPlayerIndex = selectedPlayerIndex {
                ImagePicker(selectedImage: $viewModel.playerPhotos[selectedPlayerIndex], sourceType: .camera)
            }
        }
    }
}
