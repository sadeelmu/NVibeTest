//
//  RouteStep.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import Foundation
import CoreLocation

/// contain the individual step in the route with instructions and location info
struct RouteStep: Decodable, Identifiable {
    /// A single navigation step with instructions, distance, and polyline
    let id = UUID()
    let htmlInstructions: String
    let distance: Distance
    let duration: Duration
    let polyline: Polyline
    let startLocation: Location
    let endLocation: Location

    enum CodingKeys: String, CodingKey {
        case htmlInstructions = "html_instructions"
        case distance
        case duration
        case polyline
        case startLocation = "start_location"
        case endLocation = "end_location"
    }
}

// MARK: - Supporting structs for RouteStep

struct Distance: Codable {
    let text: String
    let value: Int
}

struct Duration: Codable {
    let text: String
    let value: Int
}

struct Polyline: Codable {
    /// Encoded polyline representing a path
    let points: String
}

struct Location: Codable {
    let lat: Double
    let lng: Double
    
    /// Convenience computed property for CLLocationCoordinate2D.
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

