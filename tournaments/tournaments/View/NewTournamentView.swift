import SwiftUI

struct NewTournamentView: View {
    @ObservedObject var viewModel: NewTournamentViewModel
    @State private var showImagePicker = false
    @State private var selectedPlayerIndex: Int? = nil
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let eliminationPlayerCounts = [2, 4, 8, 16, 32, 64]
    
    var body: some View {
        VStack {
            Text("Create Tournament")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Form {
                Section(header: Text("Name your tournament")) {
                    TextField("Tournament Name", text: $viewModel.tournamentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Section(header: Text("Owner")) {
                    TextField("Owner Name", text: $viewModel.owner)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Section(header: Text("Select sport")) {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        Text("Select a sport").tag(String?.none)
                        ForEach(viewModel.sportTypes.keys.sorted(), id: \.self) { sport in
                            Text(sport).tag(String?.some(sport))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                if let selectedSport = viewModel.selectedSport {
                    Section(header: Text("Tournament mod")) {
                        Picker("Tournament", selection: $viewModel.selectedType) {
                            ForEach(viewModel.sportTypes[selectedSport] ?? [], id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
                if viewModel.selectedType == "Round Robin" {
                    Toggle(isOn: $viewModel.riposeMateches) {
                        Text("Include ripose Matches")
                    }
                }
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
                                
                                Spacer() // Přidání Spaceru
                            }
                            .padding(.vertical)
                        }
                    }
                }
                
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
