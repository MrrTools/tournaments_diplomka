//
//  User.swift
//  tournaments
//
//  Created by Lukas Sarocky on 27.02.2025.
//


import Foundation
import RealmSwift

class AppUser: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var email: String
    @Persisted var hashedPassword: String
    @Persisted var createdAt: Date = Date()
    
    convenience init(email: String, hashedPassword: String) {
        self.init()
        self.email = email
        self.hashedPassword = hashedPassword
    }
}
