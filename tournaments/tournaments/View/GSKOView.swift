import SwiftUI
import RealmSwift

struct GSKOView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    let numberOfGroups: Int
    
    // Vyberaná skupina (0-based: Group A=0, B=1, ...)
    @State private var selectedGroupIndex = 0
    
    // Vyberaná „karta“ (0 = Table, 1 = Matches)
    @State private var selectedTabIndex = 0
    
    // Premenné pre úpravu skóre
    @State private var showScoreDialog = false
    @State private var selectedMatch: Match?
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Názov turnaja
            Text(viewModel.tournament.name)
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
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
            
            // 1) Picker pre výber skupiny
            Picker("Skupina", selection: $selectedGroupIndex) {
                ForEach(0..<numberOfGroups, id: \.self) { index in
                    Text("Group \(Character(UnicodeScalar(65 + index)!))")
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            
            // 2) Picker pre voľbu Table / Matches
            Picker("", selection: $selectedTabIndex) {
                Text("Table").tag(0)
                Text("Matches").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // 3) Základné „prepínanie“ tabov v pozadí
            //    miesto .tabItem() použijeme selection + .tag()
            //    a .page(...) pre skrytie indikátora
            TabView(selection: $selectedTabIndex) {
                // TABLE
                LeaderBoardView(
                    table: groupTableEntries,
                    viewModel: viewModel
                )
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
        .navigationTitle("Skupinová fáza")
        .onAppear {
            // Načítanie z DB
            viewModel.loadTable()
            viewModel.loadMatches()
            // Môžete napr. resetnúť kolo
            viewModel.selectedRound = 1
        }
        .sheet(isPresented: $showSettings) {
            if let settings = viewModel.tournament.settings.first {
                SettingsView(settings: settings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: Binding(            get: { showScoreDialog },
                                                set: { showScoreDialog = $0 }
                                   ))
        {
            if let match = selectedMatch {
                EditModalDialogView(match: match, isPresented: $showScoreDialog, onSave: viewModel.updateMatchScore)
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
