import SwiftUI
import RealmSwift

struct GSKOView: View {
    @ObservedObject var gskoVM: GSKOViewModel
    @ObservedObject var viewModel: TournamentGenerateModel
    
    let numberOfGroups: Int
    @State private var selectedTabIndex = 0
    @State private var showScoreDialog = false
    @State private var selectedMatch: TournamentMatch?
    @State private var showSettings = false
    @State private var rematchFlag = 0
    @State private var koFlag = false
    
    var body: some View {
        ZStack {
            // Background image
            if let backgroundImageData = viewModel.tournament.backgroundImageData,
               let uiImage = UIImage(data: backgroundImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.3)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }

            // Content
            VStack(spacing: 16) {
                tournamentHeader

                if gskoVM.showHideComponets {
                    stagePicker
                }

                if gskoVM.showKnockoutStage {
                    SingleEliminationView(viewModel: gskoVM.viewModel)
                        .transition(.opacity)
                } else {
                    groupStageView
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Group Stage")
        .onAppear {
            loadData()
        }
        .onDisappear {
            // Pri opustení view resetujeme na group stage
            // Aby sa pri návrate vždy zobrazila group stage (ak KO neexistuje)
            if !viewModel.matches.contains(where: { $0.groupIndex == 0 }) {
                gskoVM.showKnockoutStage = false
            }
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .sheet(isPresented: Binding(
            get: { showScoreDialog && !gskoVM.showHideComponets },
            set: { showScoreDialog = $0 }
        )) {
            scoreEditSheet
        }
    }
    
    private var tournamentHeader: some View {
        VStack {
            Text(gskoVM.viewModel.tournament.name)
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
        }
    }
    
    private var stagePicker: some View {
        Picker("Stage", selection: $gskoVM.showKnockoutStage) {
            Text("Group Stage").tag(false)
            Text("Knockout Stage").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    private var groupStageView: some View {
        VStack(spacing: 16) {
            Picker("Skupina", selection: $gskoVM.selectedGroupIndex) {
                ForEach(0..<numberOfGroups, id: \.self) { index in
                    Text("Group \(Character(UnicodeScalar(65 + index)!))")
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: gskoVM.selectedGroupIndex) { newIndex in
                gskoVM.viewModel.selectedGroupIndex = newIndex
                gskoVM.viewModel.loadMatches()
                gskoVM.viewModel.loadTable()
                gskoVM.filterData()
            }
            
            Picker("", selection: $selectedTabIndex) {
                Text("Table").tag(0)
                Text("Matches").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedTabIndex) { newIndex in
                if newIndex == 0 { // Ak sa používateľ prepne na "Table"
                    gskoVM.viewModel.loadTable()
                }
            }
            
            TabView(selection: $selectedTabIndex) {
                groupTableView.tag(0)
                matchesListView.tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 500)
            
            Spacer()
        }
    }
    
    private var groupTableView: some View {
        VStack(spacing: 0) {
            LeaderBoardView(
                table: gskoVM.filteredTable,
                viewModel: gskoVM.viewModel
            )
            .frame(minHeight: 300)
            
            if !gskoVM.showHideComponets {
                Button(action: {
                    gskoVM.proceedAfterAllResults()
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
    }
    
    private var matchesListView: some View {
        MatchesView(
            viewModel: gskoVM.viewModel,
            showScoreDialog: $showScoreDialog,
            selectedMatch: $selectedMatch
        )
    }
    
    private var settingsSheet: some View {
        if let settings = viewModel.tournament.settings.first {
            return AnyView(
                SettingsView(settings: settings, isPresented: $showSettings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private var scoreEditSheet: some View {
        if let match = selectedMatch {
            return AnyView(
                EditModalDialogView(
                    match: match,
                    isPresented: $showScoreDialog,
                    rematchFlag: rematchFlag,
                    koFlag: koFlag,
                    onSave: viewModel.updateMatchScore
                )
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private func loadData() {
        // Najprv načítame dáta z databázy
        viewModel.loadMatches()
        viewModel.loadTable()

        // Potom skontrolujeme stav KO stage
        gskoVM.checkIfKnockoutStageExists()
        gskoVM.filterData()

        // Nastavíme showKnockoutStage podľa toho, či KO zápasy existujú
        // Ak KO zápasy existujú → zobraz KO stage
        // Ak neexistujú → zobraz group stage
        let koMatchesExist = viewModel.matches.contains(where: { $0.groupIndex == 0 })
        gskoVM.showKnockoutStage = koMatchesExist
    }
}
