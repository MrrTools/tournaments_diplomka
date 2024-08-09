//
//  SettingsView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 10.08.2024.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RoundRobinViewModel
    @Environment(\.presentationMode) var presentationMode
    
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
                    Text("Win score")
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            if viewModel.selectedRound > 0 {
                                viewModel.selectedRound -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(viewModel.selectedRound)")
                        Button(action: {
                            viewModel.selectedRound += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .padding()
                
                HStack {
                    Text("Lose score")
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            if viewModel.selectedRound > 0 {
                                viewModel.selectedRound -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(viewModel.selectedRound)")
                        Button(action: {
                            viewModel.selectedRound += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .padding()
                
                HStack {
                    Text("Draw score")
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            if viewModel.selectedRound > 0 {
                                viewModel.selectedRound -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        Text("\(viewModel.selectedRound)")
                        Button(action: {
                            viewModel.selectedRound += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
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
}
