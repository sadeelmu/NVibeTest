//
//  NVibeTestApp.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 12/05/2025.
//

import SwiftUI
import RxSwift
import RxCocoa

@main
struct NVibeTestApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationViewUI(viewModelWrapper: NavigationViewModelWrapper(viewModel: NavigationViewModel()))
        }
    }
}

