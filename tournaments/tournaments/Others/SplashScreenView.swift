//
//  SplashScreenView.swift
//  tournaments
//
//  Created by Lukas Sarocky on 28.02.2025.
//


import SwiftUI

struct SplashScreenView: View {
    @StateObject private var realmManager = RealmManager.shared
    @State private var fadeOut = false // 🔹 Pre plynulý prechod

    var body: some View {
        ZStack {
            Color.blue.edgesIgnoringSafeArea(.all) // Rovnaké ako v LaunchScreen.storyboard
            
            VStack {
                Image("image") // 🔹 Musí byť v assetoch
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                Text("Tournaments App")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            .opacity(fadeOut ? 0 : 1) // Efekt fade-out pri prechode
        }
        .onAppear {
            Task {
                await realmManager.initialize()
            }
        }
        .onChange(of: realmManager.isInitialized) { initialized in
            if initialized {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        fadeOut = true
                    }
                }
            }
        }
    }
}
