//
//  NVibeTestApp.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 12/05/2025.
//

import SwiftUI
import RxSwift
import RxCocoa

// A DisposeBag holds Rx subscriptions for the app's lifecycle
let disposeBag = DisposeBag()

@main
struct NVibeTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear{
                    Observable.of("testing", "test","RXswift here")
                        .subscribe(onNext: {print($0)}).disposed(by: disposeBag)
                }
        }
    }
}
