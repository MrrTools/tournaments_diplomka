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
    @Persisted var photoData: Data?
    @Persisted var team: String = ""
    
    convenience init(name: String, team: String, photoData: Data? = nil) {
        self.init()
        self.name = name
        self.team = team
        self.photoData = photoData
    }
}
