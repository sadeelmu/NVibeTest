//
//  RouteService.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import Foundation

import Foundation
import RxSwift
import CoreLocation

// MARK: - RouteService
///Service responsible for fetching route data from Google Directions API. handles calling the Google Directions API and parsing the JSON

class RouteService: RouteServiceProtocol {
    
    // MARK: - Properties
    private let apiKey = "AIzaSyA90XcualPjWXuVmlvfpUnvcVLP3WLu7Ng" 
    private let baseURL = "https://maps.googleapis.com/maps/api/directions/json"

    // MARK: - Public Method
    /// Fetches pedestrian route from origin to destination.
    /// - Parameters:
    ///   - origin: Start location (address string).
    ///   - destination: End location (address string).
    /// - Returns: Observable emitting RouteModel or error.
    func fetchRoute(from origin: String, to destination: String) -> Observable<RouteModel> {
        guard let url = buildURL(origin: origin, destination: destination) else {
            return Observable.error(RouteServiceError.invalidURL)
        }

        let request = URLRequest(url: url)

        return URLSession.shared.rx.data(request: request)
            .map { data -> RouteModel in
                do {
                    let routeModel = try JSONDecoder().decode(RouteModel.self, from: data)
                    return routeModel
                } catch {
                    throw RouteServiceError.decodingError(error)
                }
            }
            .catch { error in
                return Observable.error(RouteServiceError.networkError(error))
            }
    }

    // MARK: - Private Helpers
    private func buildURL(origin: String, destination: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "mode", value: "walking"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        return components?.url
    }
}

// MARK: - RouteService Errors

enum RouteServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}
