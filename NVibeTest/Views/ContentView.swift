//
//  ContentView.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 12/05/2025.
//

import SwiftUI

struct ContentView: View {
    private let viewModel = NavigationViewModel()
    private let viewModelWrapper: NavigationViewModelWrapper

    init() {
        self.viewModelWrapper = NavigationViewModelWrapper(viewModel: viewModel)
    }

    var body: some View {
        NavigationViewUI(viewModelWrapper: viewModelWrapper)
            .accentColor(.blue) // Stylish accent color for NavigationView links/buttons
    }
}

#Preview {
    ContentView()
}
