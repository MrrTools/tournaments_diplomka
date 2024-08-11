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
    
    @State private var winScore: Int
    @State private var loseScore: Int
    @State private var drawScore: Int
    
    init(settings: TournamentSettings) {
        self.settings = settings
        _winScore = State(initialValue: settings.winPoints)
        _loseScore = State(initialValue: settings.losePoints)
        _drawScore = State(initialValue: settings.drawPoints)
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
                            if winScore > 0 {
                                winScore -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(winScore)")
                        Button(action: {
                            winScore += 1
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
                            if loseScore > 0 {
                                loseScore -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(loseScore)")
                        Button(action: {
                            loseScore += 1
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
                            if drawScore > 0 {
                                drawScore -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(drawScore)")
                        Button(action: {
                            drawScore += 1
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
            settings.winPoints = winScore
            settings.losePoints = loseScore
            settings.drawPoints = drawScore
            realm.add(settings, update: .modified)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
