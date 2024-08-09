//
//  tournamentsApp.swift
//  tournaments
//
//  Created by Lukas Sarocky on 19.04.2024.
//
//application-0-hxrezkd

import SwiftUI
import RealmSwift

@main
struct tournamentsApp: SwiftUI.App {
    @StateObject private var realmManager = RealmManager.shared
    var body: some Scene {
        WindowGroup {
            
            VStack {
                
                if let configuration = realmManager.configuration, let realm = realmManager.realm {
                    MainPageView()
                        .preferredColorScheme(.dark)
                        .environment(\.realmConfiguration, configuration)
                        .environment(\.realm, realm)
                }
                
                
            }.task {
                try? await realmManager.initialize()
            }
        }
    }
}
