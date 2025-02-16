import SwiftUI
import RealmSwift

struct GSKOView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @ObservedObject var gskoVM: GSKOViewModel
    let numberOfGroups: Int
    
    @State private var selectedGroupIndex = 0
    @State private var selectedTabIndex = 0
    @State private var showScoreDialog = false
    @State private var selectedMatch: Match?
    @State private var showSettings = false
    @State private var rematchFlag = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Horný nadpis
            Text(viewModel.tournament.name)
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            // Prvky vpravo hore (nastavenia)
            HStack {
                Spacer()
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                }
            }
            .padding(.trailing)
            
            // Picker pre výber skupiny
            Picker("Skupina", selection: $selectedGroupIndex) {
                ForEach(0..<numberOfGroups, id: \.self) { index in
                    Text("Group \(Character(UnicodeScalar(65 + index)!))")
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            // iOS 17 - onChange s dvoma parametrami
            .onChange(of: selectedGroupIndex) { newValue, transaction in
                viewModel.selectedGroupIndex = newValue
            }
            
            // Picker pre prepínanie Table / Matches
            Picker("", selection: $selectedTabIndex) {
                Text("Table").tag(0)
                Text("Matches").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // TabView
            TabView(selection: $selectedTabIndex) {
                // TABLE
                VStack(spacing: 0) {
                    LeaderBoardView(
                        table: groupTableEntries,
                        viewModel: viewModel
                    )
                    .frame(minHeight: 300)
                    
                    // Tlačidlo "Proceed" - pod tabuľkou
                    Button(action: {
                        gskoVM.proceedAfterAllResults()
                    }) {
                        Text("Knock Out Stage")
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
