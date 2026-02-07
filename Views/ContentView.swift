//
//  ContentView.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated, let userId = authService.currentUserId {
                HomeView(userId: userId)
            } else {
                SplashView(authService: authService)
            }
        }
    }
}
