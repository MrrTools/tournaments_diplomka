//
//  EditModalDialogView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 17.08.2024.
//

//Definition
//Binding znamená, že tato proměnná je propojena s nějakým externím stavem, takže změna této proměnné ovlivní stav v rodičovském pohledu.
//@State znamená, že SwiftUI tuto proměnnou sleduje a znovu vykreslí UI při její změně.

import SwiftUI

struct EditModalDialogView: View {
    var match: Match
    @Binding var isPresented: Bool
    @State private var player1Score: String = ""
    @State private var player2Score: String = ""
    var onSave: (Match, Int, Int) -> Void
    
    var body: some View {
        ZStack {
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
                
                Text("Enter Score")
                    .font(.headline)
                    .padding()
                
                HStack {
                    VStack {
                        Text(match.player1?.name ?? "TBD")
                        if let photoData = match.player1?.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                        }
                        TextField("-", text: $player1Score)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("VS")
                        .font(.largeTitle)
                        .padding()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack {
                        Text(match.player2?.name ?? "TBD")
                        if let photoData = match.player2?.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                        }
                        TextField("-", text: $player2Score)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                DatePicker("Date", selection: .constant(Date()), displayedComponents: .date)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if let p1Score = Int(player1Score), let p2Score = Int(player2Score) {
                        onSave(match, p1Score, p2Score)
                        isPresented = false
                    }
                }) {
                    Text("Update")
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
            .shadow(radius: 20)
        }
    }
}
