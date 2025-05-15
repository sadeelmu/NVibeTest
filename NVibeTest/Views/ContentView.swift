//
//  ContentView.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 12/05/2025.
//

import SwiftUI

struct ContentView: View {
    private let viewModel = NavigationViewModel()

    var body: some View {
        NavigationViewUI(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
