//
//  HomeView.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import SwiftUI

struct HomeView: View {
    let userId: String
    @State private var showMatching = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("جاهز للدردشة؟")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("ابحث عن شخص عشوائي للمحادثة")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    showMatching = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("ابحث عن محادثة")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 50)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .navigationDestination(isPresented: $showMatching) {
                MatchingView(userId: userId)
            }
        }
    }
}
