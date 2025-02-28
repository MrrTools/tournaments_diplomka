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

    var body: some View {
        VStack {
            Text("Register").font(.largeTitle).bold().padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Register") {
                AuthService.shared.registerUser(email: email, password: password, confirmPassword: confirmPassword) { success, error in
                    if success {
                        print("User registered successfully")
                    } else {
                        self.errorMessage = error
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            NavigationLink("Continue without registration", destination: MainPageView(showPublicTournaments: true))
                .padding()
        }
        .padding()
    }
}
