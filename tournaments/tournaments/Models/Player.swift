//
//  Player.swift
//  tournaments
//
//  Created by Lukas Sarocky on 17.08.2024.
//

import Foundation
import RealmSwift

class Player: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String = ""
    @Persisted var photoData: Data? // To store photo
    
    convenience init(name: String, photoData: Data? = nil) {
        self.init()
        self.name = name
        self.photoData = photoData
    }
}
