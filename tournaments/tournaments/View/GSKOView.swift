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
        VStack(spacing: 16) {
            // 🏆 Názov turnaja + Nastavenia
            tournamentHeader

            // 📌 Výber medzi Group Stage a Knockout Stage
            if gskoVM.showHideComponets {
                stagePicker
            }

            // 🏆 Knockout Stage alebo Group Stage
            if gskoVM.showKnockoutStage {
                SingleEliminationView(viewModel: gskoVM.viewModel)
                    .transition(.opacity)
            } else {
                groupStageView
            }
        }
        .padding(.bottom)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
        .navigationTitle("Group Stage")
        .onAppear {
            loadData()
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

    // 🏆 Hlavný titulok + Nastavenia
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

    // 📌 Výber medzi Group Stage a Knockout Stage
    private var stagePicker: some View {
        Picker("Stage", selection: $gskoVM.showKnockoutStage) {
            Text("Group Stage").tag(false)
            Text("Knockout Stage").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // 📌 Group Stage sekcia
    private var groupStageView: some View {
        VStack(spacing: 16) {
            // 📌 Výber skupiny
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

            // 📌 Prepínanie medzi "Table" a "Matches"
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

            // 📌 Obsah pre "Table" a "Matches"
            TabView(selection: $selectedTabIndex) {
                groupTableView.tag(0)
                matchesListView.tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 500)

            Spacer()
        }
    }

    // 📊 Tabuľka skupiny
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

    // 🏆 Zápasy v skupine
    private var matchesListView: some View {
        MatchesView(
            viewModel: gskoVM.viewModel,
            showScoreDialog: $showScoreDialog,
            selectedMatch: $selectedMatch
        )
    }

    // ⚙️ Nastavenia Sheet
    private var settingsSheet: some View {
        if let settings = viewModel.tournament.settings.first {
            return AnyView(
                SettingsView(settings: settings)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // ⚽ Editácia skóre zápasu
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

    // 📌 Načítanie údajov
    private func loadData() {
        gskoVM.filterData()
        viewModel.loadTable()
        viewModel.loadMatches()
        gskoVM.checkIfKnockoutStageExists()
    }
}
