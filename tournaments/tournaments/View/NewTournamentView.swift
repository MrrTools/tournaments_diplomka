//
//  NewTournamentView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 07.07.2024.
//

import SwiftUI


struct NewTournamentView: View {
    @ObservedObject var viewModel: NewTournamentViewModel
    @State private var showImagePicker = false
    @State private var selectedPlayerIndex: Int?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State var image: UIImage?
    
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
                Section(header: Text("Players")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<Int(viewModel.numberOfPlayers), id: \.self) { index in
                            HStack {
                                Button(action: {
                                    selectedPlayerIndex = index
                                    showImagePicker = true
                                }) {
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
                                }
                                TextField("Player \(index + 1)", text: $viewModel.players[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding()
            
            Button(action: {
                viewModel.saveTournament()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Text("Generate Tournament")
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
        .sheet(isPresented: Binding(            get: { showImagePicker },
                                                set: { showImagePicker = $0 })) {
            if let selectedPlayerIndex = selectedPlayerIndex {
                ImagePicker(selectedImage: Binding(
                    get: { viewModel.playerPhotos[selectedPlayerIndex] },
                    set: { newImage in viewModel.playerPhotos[selectedPlayerIndex] = newImage }
                ))
            }
        }
    }
}

#Preview {
    NewTournamentView(viewModel: NewTournamentViewModel(onSave: { }))
}
