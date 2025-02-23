import SwiftUI

struct NewTournamentView: View {
    @ObservedObject var viewModel: NewTournamentViewModel
    
    @State private var showImagePicker = false
    @State private var selectedPlayerIndex: Int? = nil
    
    @Environment(\.presentationMode) var presentationMode
    
    // Možné počty hráčov podľa typu turnaja
    let eliminationPlayerCounts = [2, 4, 8, 16, 32, 64]
    let groupStageKO = [4, 8, 16, 32, 64]
    let playOffNHL = [2, 4, 8, 16]
    
    // Chybové zprávy
    @State private var nameError: String?
    @State private var ownerError: String?
    @State private var sportError: String?
    @State private var typeError: String?
    @State private var playersErrors: [Int: String] = [:]
    @State private var f1TeamsError: [Int: String] = [:]
    
    // Pre jednoduchosť extrahujeme dostupné možnosti do computed property
    var availableCounts: [Int] {
        switch viewModel.selectedType {
        case "Group Stage and KO":
            return groupStageKO
        case "Playoff":
            return playOffNHL
        case "Single Elimination", "Double Elimination":
            return eliminationPlayerCounts
        default:
            return Array(2...64)
        }
    }
    
    var body: some View {
        VStack {
            Text("Create Tournament")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Form {
                tournamentNameSection
                tournamentOwnerSection
                sportSection
                if viewModel.selectedSport != nil {
                    tournamentTypeSection
                }
                if viewModel.selectedType == "Round Robin" || viewModel.selectedType == "Group Stage and KO" {
                    riposeMatchesSection
                } else if viewModel.selectedType == "Championship" {
                    racesSection
                } else if viewModel.selectedType == "Playoff" {
                    playoffSection
                }
                playersCountSection
                if viewModel.selectedType == "Round Robin" || viewModel.selectedType == "Group Stage and KO" {
                    groupStageSection
                }
                playersSection
                photoSection
            }
            .padding()
            
            createTournamentButton
        }
        .background(Color.black.opacity(0.9))
        .foregroundColor(.white)
        .sheet(isPresented: $showImagePicker) {
            if let selectedIndex = selectedPlayerIndex {
                ImagePicker(
                    selectedImage: $viewModel.playerPhotos[selectedIndex],
                    sourceType: .camera
                )
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var tournamentNameSection: some View {
        Section(header: Text("Tournament Name")) {
            TextField("Tournament Name", text: $viewModel.tournamentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let nameError = nameError {
                Text(nameError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var tournamentOwnerSection: some View {
        Section(header: Text("Tournament Owner")) {
            TextField("Tournament Owner", text: $viewModel.owner)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let ownerError = ownerError {
                Text(ownerError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var sportSection: some View {
        Section(header: Text("Sport")) {
            Picker("Sport", selection: $viewModel.selectedSport) {
                Text("Pick up Sport").tag(String?.none)
                ForEach(viewModel.sportTypes.keys.sorted(), id: \.self) { sport in
                    Text(sport).tag(String?.some(sport))
                }
            }
            .pickerStyle(.navigationLink)
            if let sportError = sportError {
                Text(sportError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var tournamentTypeSection: some View {
        Section(header: Text("Tournament type")) {
            Picker("Type", selection: $viewModel.selectedType) {
                Text("Pick up Tournament Type").tag(String?.none)
                if let selectedSport = viewModel.selectedSport {
                    ForEach(viewModel.sportTypes[selectedSport] ?? [], id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }
            .pickerStyle(.navigationLink)
            if let typeError = typeError {
                Text(typeError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var riposeMatchesSection: some View {
        Group {
            Toggle(isOn: $viewModel.riposeMateches) {
                Text("Ripose Matches")
            }
            if viewModel.selectedType == "Group Stage and KO" {
                Toggle(isOn: $viewModel.riposeFinal) {
                    Text("Two Legs Final")
                }
                Toggle(isOn: $viewModel.riposeKnockOut) {
                    Text("Two Legs in Knock Out Stage")
                }
            }
        }
    }
    
    private var racesSection: some View {
        Section(header: Text("Počet pretekov")) {
            VStack {
                Slider(
                    value: $viewModel.numberOfRaces,
                    in: 3...30,
                    step: 1,
                    onEditingChanged: { editing in
                        viewModel.isEditing = editing
                    }
                )
                Text("Počet pretekov: \(Int(viewModel.numberOfRaces))")
                    .foregroundColor(viewModel.isEditing ? .red : .purple)
            }
        }
    }
    
    private var playoffSection: some View {
        Section(header: Text("Počet víťazných zápasov")) {
            Picker("Počet víťazných zápasov", selection: $viewModel.playOFFMatches) {
                ForEach([3, 5, 7], id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var playersCountSection: some View {
        Section(header: Text("Počet hráčů")) {
            VStack {
                Slider(
                    value: Binding(
                        get: { Double(viewModel.numberOfPlayers) },
                        set: { newValue in
                            let newIntValue = Int(newValue)
                            if availableCounts.contains(newIntValue) {
                                viewModel.numberOfPlayers = Double(newIntValue)
                            } else if let closest = availableCounts.min(by: { abs($0 - newIntValue) < abs($1 - newIntValue) }) {
                                viewModel.numberOfPlayers = Double(closest)
                            }
                        }
                    ),
                    in: Double(availableCounts.first ?? 2)...Double(availableCounts.last ?? 64),
                    step: 1
                )
                Text("Počet hráčů: \(Int(viewModel.numberOfPlayers))")
                    .foregroundColor(viewModel.isEditing ? .red : .purple)
            }
        }
    }
    
    // Sekcia pre Group Stage and KO – používa computed properties z view modelu
    private var groupStageSection: some View {
        Section(header: Text("Group Stage Settings")) {
            Picker("Teams per Group", selection: $viewModel.numberOfGroupPlayers) {
                ForEach(viewModel.teamsPerGroupOptions, id: \.self) { option in
                    Text("\(option)").tag(option)
                }
            }
            .pickerStyle(.menu)
            
            Picker("Advancing Teams", selection: $viewModel.numberOfAdvancePlayers) {
                ForEach(viewModel.advancingOptions, id: \.self) { option in
                    Text("\(option)").tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var playersSection: some View {
        Section(header: Text("Hráči")) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(0..<Int(viewModel.numberOfPlayers), id: \.self) { index in
                    VStack {
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
                            TextField("Hráč \(index + 1)", text: $viewModel.players[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .multilineTextAlignment(.center)
                            Spacer()
                            if viewModel.selectedType == "Championship" {
                                TextField("Team F1", text: $viewModel.f1Teams[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        
                        if let error = playersErrors[index] {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        if let error = f1TeamsError[index] {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    private var photoSection: some View {
        Section(header: Text("Přidat fotku hráče")) {
            HStack {
                Picker("Vyberte hráče", selection: $selectedPlayerIndex) {
                    Text("Vyberte hráče").tag(Int?.none)
                    ForEach(0..<Int(viewModel.numberOfPlayers), id: \.self) { index in
                        Text(viewModel.players[index].isEmpty ? "Hráč \(index + 1)" : viewModel.players[index])
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
                    Text("Přidat fotku")
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var createTournamentButton: some View {
        Button(action: {
            validateForm()
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
    
    // MARK: - Validace formuláře
    private func validateForm() {
        nameError = nil
        ownerError = nil
        sportError = nil
        typeError = nil
        playersErrors = [:]
        
        var isValid = true
        
        if viewModel.tournamentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Název turnaje je povinný."
            isValid = false
        }
        
        if viewModel.owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ownerError = "Jméno majitele je povinné."
            isValid = false
        }
        
        if viewModel.selectedSport == nil {
            sportError = "Musíte vybrat sport."
            isValid = false
        }
        
        if viewModel.selectedType == nil {
            typeError = "Musíte vybrat typ turnaje."
            isValid = false
        }
        
        let maxPlayers = Int(viewModel.numberOfPlayers)
        for i in 0..<maxPlayers {
            if viewModel.players[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                playersErrors[i] = "Jméno hráče je povinné."
                isValid = false
            }
        }
        
        if isValid {
            viewModel.saveTournament()
            presentationMode.wrappedValue.dismiss()
        }
    }
}
