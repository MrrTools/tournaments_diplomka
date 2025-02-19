import SwiftUI

struct NewTournamentView: View {
    @ObservedObject var viewModel: NewTournamentViewModel
    
    @State private var showImagePicker = false
    @State private var selectedPlayerIndex: Int? = nil
    
    @Environment(\.presentationMode) var presentationMode
    
    let eliminationPlayerCounts = [2, 4, 8, 16, 32, 64]
    let groupStageKO = [ 4, 8, 16, 32, 64]
    let playOffNHL = [2, 4, 8, 16]
    
    // Chybové zprávy
    @State private var nameError: String?
    @State private var ownerError: String?
    @State private var sportError: String?
    @State private var typeError: String?
    @State private var playersErrors: [Int: String] = [:]
    @State private var f1TeamsError: [Int: String] = [:]
    
    var body: some View {
        VStack {
            Text("Vytvořit turnaj")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Form {
                // Název turnaje
                Section(header: Text("Název turnaje")) {
                    TextField("Název turnaje", text: $viewModel.tournamentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Zobrazení chyby
                    if let nameError = nameError {
                        Text(nameError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Majitel turnaje
                Section(header: Text("Majitel turnaje")) {
                    TextField("Vaše jméno", text: $viewModel.owner)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Zobrazení chyby
                    if let ownerError = ownerError {
                        Text(ownerError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Výběr sportu
                Section(header: Text("Zvolte sport")) {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        Text("Vyberte sport").tag(String?.none)
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
                
                // Výběr turnajového módu
                if let selectedSport = viewModel.selectedSport {
                    Section(header: Text("Typ turnaje")) {
                        Picker("Typ", selection: $viewModel.selectedType) {
                            Text("Vyberte typ turnaje").tag(String?.none)
                            ForEach(viewModel.sportTypes[selectedSport] ?? [], id: \.self) { type in
                                Text(type).tag(type)
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
                
                // Možnost zapnout ripose zápasy, pokud je vybrán Round Robin
                if viewModel.selectedType == "Round Robin" || viewModel.selectedType ==  "Group Stage and KO"{
                    Toggle(isOn: $viewModel.riposeMateches) {
                        Text("Zahrnout ripose zápasy")
                    }
                }
                else if viewModel.selectedType == "Championship" {
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
                } else if  viewModel.selectedType == "Playoff"{
                    Section(header: Text("Počet víťazných zápasov")) {
                        Picker("Počet víťazných zápasov", selection: $viewModel.playOFFMatches) {
                            ForEach([3, 5, 7], id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle()) // Zobrazenie ako tlačidlá
                    }

                }
                
                // Počet hráčů
                Section(header: Text("Počet hráčů")) {
                    VStack {
                        // Výber dostupných možností podľa typu turnaja
                        let availableCounts: [Int] = {
                            switch viewModel.selectedType {
                            case "Group Stage and KO":
                                return groupStageKO
                            case "Playoff":
                                return playOffNHL
                            case "Single Elimination", "Double Elimination":
                                return eliminationPlayerCounts
                            default:
                                return Array(2...64) // Pre ostatné turnaje voľný výber
                            }
                        }()
                        

                        // Aktualizovaný `Binding` pre `Slider`
                        let playerBinding = Binding<Double>(
                            get: { Double(viewModel.numberOfPlayers) },
                            set: { newValue in
                                let newIntValue = Int(newValue)
                                if availableCounts.contains(newIntValue) {
                                    viewModel.numberOfPlayers = Double(newIntValue)
                                } else if let closest = availableCounts.min(by: { abs($0 - newIntValue) < abs($1 - newIntValue) }) {
                                    viewModel.numberOfPlayers = Double(closest)
                                }
                            }
                        )
                        
                        Slider(
                            value: playerBinding,
                            in: Double(availableCounts.first ?? 2)...Double(availableCounts.last ?? 64),
                            step: 1
                        )
                        
                        Text("Počet hráčů: \(Int(viewModel.numberOfPlayers))")
                            .foregroundColor(viewModel.isEditing ? .red : .purple)
                    }
                }
                
                // Zadávání hráčů
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
                                
                                // Zobrazení chyby pod polem pro každého hráče
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
                
                // Přidání fotky hráče
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
            .padding()
            
            // Tlačítko Vytvořit turnaj
            Button(action: {
                validateForm()
            }) {
                HStack {
                    Text("Vytvořit turnaj")
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
            if let selectedIndex = selectedPlayerIndex {
                ImagePicker(
                    selectedImage: $viewModel.playerPhotos[selectedIndex],
                    sourceType: .camera
                )
            }
        }
    }
    
    // MARK: - Validace formuláře
    private func validateForm() {
        // Nejprve vynulujeme chyby
        nameError = nil
        ownerError = nil
        sportError = nil
        typeError = nil
        playersErrors = [:]
        
        var isValid = true
        
        // 1) Validace názvu turnaje
        if viewModel.tournamentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Název turnaje je povinný."
            isValid = false
        }
        
        // 2) Validace jména majitele
        if viewModel.owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ownerError = "Jméno majitele je povinné."
            isValid = false
        }
        
        // 3) Validace sportu
        if viewModel.selectedSport == nil {
            sportError = "Musíte vybrat sport."
            isValid = false
        }
        
        // 4) Validace typu turnaje
        if viewModel.selectedType == nil {
            typeError = "Musíte vybrat typ turnaje."
            isValid = false
        }
        
        // 5) Validace hráčů
        let maxPlayers = Int(viewModel.numberOfPlayers)
        for i in 0..<maxPlayers {
            if viewModel.players[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                playersErrors[i] = "Jméno hráče je povinné."
                isValid = false
            }
        }
        
        // 6) F1 validacie
        var teamFrequencies: [String: Int] = [:]
        for team in viewModel.f1Teams {
            let trimmedTeam = team.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTeam.isEmpty {
                teamFrequencies[trimmedTeam, default: 0] += 1
            }
        }
        
        // Nyní ověříme každý textfield
        /*      for (index, team) in viewModel.f1Teams.enumerated() {
         let trimmedTeam = team.trimmingCharacters(in: .whitespacesAndNewlines)
         if trimmedTeam.isEmpty {
         f1TeamsError[index] = "Jméno teamu je povinné."
         isValid = false
         } else if let count = teamFrequencies[trimmedTeam], count >= 3 {
         f1TeamsError[index] = "Maximálně 2 hráči mohou mít stejný tým."
         isValid = false
         }
         }*/
        
        
        // Pokud je formulář validní, teprve potom uložíme a zavřeme obrazovku
        if isValid {
            viewModel.saveTournament()
            presentationMode.wrappedValue.dismiss()
        }
    }
}
