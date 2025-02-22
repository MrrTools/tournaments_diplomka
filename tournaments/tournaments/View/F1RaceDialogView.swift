//
//  F1RaceDialog.swift
//  tournaments
//
//  Created by Lukas Sarocky on 22.02.2025.
//

import SwiftUI

struct F1RaceDialogView: View {
    var race: Int?
    @ObservedObject var viewModel: F1ViewModel
    @Binding var isPresented: Bool
    @State private var raceName = ""
    @State private var country = ""
    @State private var laps = 50
    @State private var date = Date()
    let selectedRaceNumber: Int
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                Form {
                    Section(header: Text("Race Name")) {
                        TextField("Race Name", text: $raceName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Section(header: Text("Country")) {
                        TextField("Country", text: $country)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Section(header: Text("Laps")) {
                        Stepper("Laps: \(laps)", value: $laps, in: 1...100)
                    }
                    Section(header: Text("Date")) {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    }
                    .navigationTitle("Add Race")
                }
                // Tlačítko Vytvořit turnaj
                Button(action: {
                    isPresented = false
                    viewModel.addRace(name: raceName,country: country, laps: laps,
                        date: date, raceNumber: selectedRaceNumber
                    )
                }) {
                    HStack {
                        Text("Create Race")
                        Image(systemName: "checkmark.circle")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.purple)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}
