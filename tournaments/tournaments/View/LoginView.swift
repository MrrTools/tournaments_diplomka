//
//  LoginView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 27.02.2025.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var navigateToMainPage = false
    @State private var showPublicTournaments = false

    var body: some View {
        NavigationStack {
            VStack {
                

                Text("Login")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Form {
                    Section {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)

                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }

                        Button(action: {
                            AuthService.shared.loginUser(email: email, password: password) { success, error, user in
                                if success {
                                    showPublicTournaments = false
                                    navigateToMainPage = true
                                } else {
                                    self.errorMessage = error
                                }
                            }
                        }) {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }

                    Section {
                        NavigationLink("Register", destination: RegistrationView())
                            .frame(maxWidth: .infinity)
                    }

                    Section {
                        Button(action: {
                            showPublicTournaments = true
                            navigateToMainPage = true
                        }) {
                            Text("Continue without registration")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.purple)
                    }
                }

                Spacer() // Posunie Form hore, aby bol v strede obrazovky
            }
            .padding()
            .frame(maxHeight: .infinity) // Rozťahuje obsah na celú výšku
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            .navigationDestination(isPresented: $navigateToMainPage) {
                MainPageView(showPublicTournaments: showPublicTournaments)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}




