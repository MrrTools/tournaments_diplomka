import SwiftUI
import RealmSwift

struct GSKOView: View {
    @ObservedObject var viewModel: TournamentGenerateModel
    @ObservedObject var gskoVM: GSKOViewModel
    
    let numberOfGroups: Int
    @State private var selectedTabIndex = 0
    
    @State private var showScoreDialog = false
    @State private var selectedMatch: TournamentMatch?
    @State private var showSettings = false
    @State private var rematchFlag = 0
    @State private var koFlag = false
    @State private var navigateToKO = false
    
    var body: some View {
        VStack(spacing: 16) {
            if !gskoVM.showKnockoutStage {
                Text(viewModel.tournament.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                // Riadok s tlačidlom "Settings" (gear)
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
            }
            // Picker na prepínanie STAGE (Group / Knockout)
            if  gskoVM.showHideComponets { Picker("Stage", selection: $gskoVM.showKnockoutStage) {
                Text("Group Stage").tag(false)
                Text("Knockout Stage").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            }
            
            // V závislosti od stavu Knockout Stage zobraziť buď SingleEliminationView, alebo Group Stage
            if gskoVM.showKnockoutStage || navigateToKO {
                // KO fáza
                SingleEliminationView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                // GROUP STAGE UI
                VStack(spacing: 16) {
                    
                    // Picker na výber skupín
                    Picker("Skupina", selection: $viewModel.selectedGroupIndex) {
                        ForEach(0..<numberOfGroups, id: \.self) { index in
                            Text("Group \(Character(UnicodeScalar(65 + index)!))")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Druhý picker (TabView) na zobrazenie "Table" alebo "Matches"
                    Picker("", selection: $selectedTabIndex) {
                        Text("Table").tag(0)
                        Text("Matches").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    TabView(selection: $selectedTabIndex) {
                        
                        // TABLE zobrazenie
                        VStack(spacing: 0) {
                            LeaderBoardView(
                                table: groupTableEntries,
                                viewModel: viewModel
                            )
                            .frame(minHeight: 300)
                            
                            if !gskoVM.showHideComponets {
                                Button(action: {
                                    gskoVM.proceedAfterAllResults()
                                    gskoVM.showHideComponets = true

                                    

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
                            
                        }
                        .tag(0)
                        
                        // MATCHES zobrazenie
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
            // Načítanie potrebných údajov
            viewModel.loadTable()
            viewModel.loadMatches()
            viewModel.selectedRound = 1
            gskoVM.checkIfKnockoutStageExists()
        }
        // Sheet pre zobrazenie nastavení
        .sheet(isPresented: $showSettings) {
            if let settings = viewModel.tournament.settings.first {
                SettingsView(settings: settings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Sheet pre zobrazenie editácie skóre zápasu
        .sheet(isPresented: Binding(get: { showScoreDialog && !gskoVM.showHideComponets },
                                    set: { showScoreDialog = $0 })) {
            if let match = selectedMatch {
                EditModalDialogView(
                    match: match,
                    isPresented: $showScoreDialog,
                    rematchFlag: rematchFlag,
                    koFlag: koFlag,
                    onSave: viewModel.updateMatchScore
                )
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // Vyberá iba hráčov (TournamentTable) z danej skupiny
    var groupTableEntries: [TournamentTable] {
        let totalPlayers = viewModel.tournament.players.count
        let playersPerGroup = totalPlayers / numberOfGroups
        let start = viewModel.selectedGroupIndex * playersPerGroup
        let end = start + playersPerGroup
        
        guard viewModel.table.count >= end else {
            return []
        }
        return Array(viewModel.table[start..<end])
    }
}
