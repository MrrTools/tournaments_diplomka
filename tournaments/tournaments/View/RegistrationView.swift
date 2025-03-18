
//
//  RegistrationView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 27.02.2025.
//


import SwiftUI

struct RegistrationView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var navigateToLogin = false
    
    var body: some View {
        VStack {
            Text("Register").font(.largeTitle).bold().padding()
            
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                Section {
                    Button(action: {
                        AuthService.shared.registerUser(email: email, password: password, confirmPassword: confirmPassword) { success, error in
                            if success {
                                print("User registered successfully")
                                navigateToLogin = true
                            } else {
                                self.errorMessage = error
                            }
                        }
                    }) {
                        Text("Register")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                Section {
                    NavigationLink("Continue without registration", destination: MainPageView(showPublicTournaments: true))
                        .padding()
                }
                
            }
            .padding()
            .frame(maxHeight: .infinity)
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}
