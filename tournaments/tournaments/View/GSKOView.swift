import SwiftUI
import RealmSwift

struct GSKOView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @ObservedObject var gskoVM: GSKOViewModel
    let numberOfGroups: Int
    
    @State private var selectedGroupIndex = 0
    @State private var selectedTabIndex = 0
    @State private var showScoreDialog = false
    @State private var selectedMatch: TournamentMatch?
    @State private var showSettings = false
    @State private var rematchFlag = 0
    
    @State private var showKnockoutPicker = false  // 🔹 Skryje Picker, pokiaľ sa neklikne na "Knockout Stage"
    @State private var showKnockoutStage = false   // 🔹 Prepína medzi Group Stage a Knockout Stage
    
    var body: some View {
        VStack(spacing: 16) {
            
            // 🔥 Picker sa zobrazí iba, ak bol aktivovaný Knockout Stage
            if showKnockoutPicker {
                Picker("Stage", selection: $showKnockoutStage) {
                    Text("Group Stage").tag(false)
                    Text("Knockout Stage").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .transition(.opacity) // Plynulý prechod pri zobrazení
            }
            
            if showKnockoutStage {
                // 🔥 Knockout fáza (Single Elimination View)
                SingleEliminationView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                // 🔥 Skupinová fáza (Pôvodný obsah)
                VStack(spacing: 16) {
                    Text(viewModel.tournament.name)
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    HStack {
                        Spacer()
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()
                        }
                    }
                    .padding(.trailing)
                    
                    Picker("Skupina", selection: $selectedGroupIndex) {
                        ForEach(0..<numberOfGroups, id: \.self) { index in
                            Text("Group \(Character(UnicodeScalar(65 + index)!))")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onChange(of: selectedGroupIndex) { newValue, transaction in
                        viewModel.selectedGroupIndex = newValue
                    }
                    
                    Picker("", selection: $selectedTabIndex) {
                        Text("Table").tag(0)
                        Text("Matches").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    TabView(selection: $selectedTabIndex) {
                        // TABLE
                        VStack(spacing: 0) {
                            LeaderBoardView(
                                table: groupTableEntries,
                                viewModel: viewModel
                            )
                            .frame(minHeight: 300)
                            
                            // 🔥 Po kliknutí na "Knockout Stage" sa aktivuje Picker a zobrazí sa Knockout fáza
                            Button(action: {
                                gskoVM.proceedAfterAllResults()
                                showKnockoutPicker = true
                                showKnockoutStage = true
                            }) {
                                Text("Knockout Stage")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: 200)
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.vertical, 16)
                            .disabled(!gskoVM.allResultsFilled)
                            .opacity(gskoVM.allResultsFilled ? 1.0 : 0.5)
                        }
                        .tag(0)
                        
                        // MATCHES
                        MatchesView(
                            viewModel: viewModel,
                            showScoreDialog: $showScoreDialog,
                            selectedMatch: $selectedMatch
                        )
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 500)
                    
                    Spacer()
                }
            }
        }
        .padding(.bottom)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
        .navigationTitle("Group Stage")
        .onAppear {
            viewModel.loadTable()
            viewModel.loadMatches()
            viewModel.selectedRound = 1
        }
        // Nastavenia
        .sheet(isPresented: $showSettings) {
            if let settings = viewModel.tournament.settings.first {
                SettingsView(settings: settings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Dialóg pre skóre zápasu
        .sheet(isPresented: Binding(get: { showScoreDialog },
                                   set: { showScoreDialog = $0 })) {
            if let match = selectedMatch {
                EditModalDialogView(match: match,
                                    isPresented: $showScoreDialog, rematchFlag: rematchFlag,
                                    onSave: viewModel.updateMatchScore)
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Tabuľkové záznamy len pre vybranú skupinu
    var groupTableEntries: [TournamentTable] {
        let totalPlayers = viewModel.tournament.players.count
        let playersPerGroup = totalPlayers / numberOfGroups
        let start = selectedGroupIndex * playersPerGroup
        let end = start + playersPerGroup
        
        guard viewModel.table.count >= end else {
            return []
        }
        return Array(viewModel.table[start..<end])
    }
}
