//
//  RouteServiceProtocol.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 15/05/2025.
//

import Foundation
import RxSwift

/// Protocol defining the interface for route fetching services.
/// Allows for abstraction and easier testing/mocking.
protocol RouteServiceProtocol {
    /// Fetches pedestrian route data from an origin to a destination.
    /// - Parameters:
    ///   - origin: Starting location address as a string
    ///   - destination: Destination location address as a string
    /// - Returns: Observable emitting a `RouteModel` on success or an error.
    func fetchRoute(from origin: String, to destination: String) -> Observable<RouteModel>
}
