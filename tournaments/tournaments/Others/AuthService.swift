//
//  AuthService.swift
//  tournaments
//
//  Created by Lukas Sarocky on 27.02.2025.
//


import Foundation
import CryptoKit
import RealmSwift
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    private var realm: Realm?

    @Published var currentUser: AppUser?

    private let userDefaultsKey = "LoggedInUserEmail"

    private init() {
        self.realm = RealmManager.shared.realm
        loadCurrentUser()
    }

    private func loadCurrentUser() {
        guard let realm = realm else { return }

        // Načítame email z UserDefaults (perzistentné uloženie)
        if let savedEmail = UserDefaults.standard.string(forKey: userDefaultsKey),
           let user = realm.objects(AppUser.self).filter("email == %@", savedEmail).first {
            currentUser = user
        } else {
            // Žiadny uložený email = užívateľ nie je prihlásený
            currentUser = nil
        }
    }

    func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func registerUser(email: String, password: String, confirmPassword: String, completion: @escaping (Bool, String?) -> Void) {
        guard let realm = realm else {
            completion(false, "Database error")
            return
        }

        guard password == confirmPassword else {
            completion(false, "Passwords do not match")
            return
        }

        let existingUser = realm.objects(AppUser.self).filter("email == %@", email).first
        guard existingUser == nil else {
            completion(false, "User already exists")
            return
        }

        let hashedPassword = hashPassword(password)
        let newUser = AppUser(email: email, hashedPassword: hashedPassword)

        try? realm.write {
            realm.add(newUser)
        }

        // Nastavíme aktuálneho používateľa PO zápise do DB
        currentUser = newUser

        // Uložíme email do UserDefaults
        UserDefaults.standard.set(email, forKey: userDefaultsKey)

        objectWillChange.send()

        completion(true, nil)
    }

    func loginUser(email: String, password: String, completion: @escaping (Bool, String?, AppUser?) -> Void) {
        guard let realm = realm else {
            completion(false, "Database error", nil)
            return
        }

        let hashedPassword = hashPassword(password)
        if let user = realm.objects(AppUser.self).filter("email == %@ AND hashedPassword == %@", email, hashedPassword).first {
            currentUser = user

            // Uložíme email do UserDefaults
            UserDefaults.standard.set(email, forKey: userDefaultsKey)

            objectWillChange.send()
            completion(true, nil, user)
        } else {
            completion(false, "Invalid email or password", nil)
        }
    }

    func logout() {
        currentUser = nil

        // Vymažeme email z UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)

        // Explicitne upovedomíme o zmene
        objectWillChange.send()
    }
}
