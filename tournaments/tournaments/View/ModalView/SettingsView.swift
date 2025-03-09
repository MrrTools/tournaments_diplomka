//
//  SettingsView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 10.08.2024.
//

import SwiftUI
import RealmSwift

struct SettingsView: View {
    var settings: TournamentSettings
    @Environment(\.presentationMode) var presentationMode
    
    @State private var winPoints: Int
    @State private var losePoints: Int
    @State private var drawPoints: Int
    
    init(settings: TournamentSettings) {
        self.settings = settings
        _winPoints = State(initialValue: settings.winPoints)
        _losePoints = State(initialValue: settings.losePoints)
        _drawPoints = State(initialValue: settings.drawPoints)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Additional settings")
                    .font(.title2)
                    .bold()
                    .padding()
                
                Spacer()
                
                HStack {
                    Text("Win Points")
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            if winPoints > 0 {
                                winPoints -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(winPoints)")
                        Button(action: {
                            winPoints += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .padding()
                
                HStack {
                    Text("Lose Points")
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            if losePoints > 0 {
                                losePoints -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(losePoints)")
                        Button(action: {
                            losePoints += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .padding()
                
                HStack {
                    Text("Draw Points")
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            if drawPoints > 0 {
                                drawPoints -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(drawPoints)")
                        Button(action: {
                            drawPoints += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    saveSettings()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .padding()
            .background(Color.black)
            .cornerRadius(8)
        }
    }
    
    private func saveSettings() {
        guard let realm = RealmManager.shared.realm else { return }
        
        try? realm.write {
            settings.winPoints = winPoints
            settings.losePoints = losePoints
            settings.drawPoints = drawPoints
            realm.add(settings, update: .modified)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
