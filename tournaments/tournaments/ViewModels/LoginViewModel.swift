//
//  LoginViewModel.swift
//  tournaments
//
//  Created by Lukas Sarocky on 04.05.2024.
//

import Foundation

class LoginViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var password: String = ""
    @Published var isLogged: Bool = false
    @Published var errorMessage: String = ""
    
    init() {}
    
    func login() {
        guard validate() else {
            return
        }
      /*  if userName == "admin" && password == "admin" {
            isLogged = true
        } else {
            errorMessage = "Invalid credentials"
        }*/
        
        print("Logged in")
    }
    
    func logout() {
        isLogged = false
    }
    
    private func validate() -> Bool {
        errorMessage = ""
        guard !userName.trimmingCharacters(in: .whitespaces).isEmpty, !password.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            errorMessage = "Please fill in all fields"
            return false
        }
        return true
    }
}
    
    
