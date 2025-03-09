//
//  SplashScreenView 2.swift
//  tournaments
//
//  Created by Lukas Sarocky on 28.02.2025.
//


import SwiftUI

struct SplashScreenView: View {
    @StateObject private var realmManager = RealmManager.shared
    @State private var fadeOut = false
    @State private var progress: Double = 0.0
    @State private var isActive = false

    var body: some View {
        if isActive {
            MainPageView()
        } else {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    Image("Image") // Nahraď svojím logom
                        .resizable()
                        .scaledToFit()
                        .opacity(fadeOut ? 0 : 1)

                    Text("Loading...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .frame(width: 200)
                        .padding()
                }
                .opacity(fadeOut ? 0 : 1)
            }
            .onAppear {
                startLoading()
                Task {
                    await realmManager.initialize()
                }
            }
            .onChange(of: realmManager.isInitialized) {
                if realmManager.isInitialized {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            fadeOut = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isActive = true
                    }
                }
            }

        }
    }

    private func startLoading() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if progress < 100 {
                progress += 2
            } else {
                timer.invalidate()
            }
        }
    }
}
