//
//  RouteModel.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import Foundation
import CoreLocation


// MARK: - RouteModel
///Root model for Directions API response: contains route response: steps, duration, distance
///
struct RouteModel: Codable {
    let routes: [Route] //list of possible routes
    let status: String //api response status
}

// MARK: - Route
/// a route containing legs and an overview polyline
struct Route: Codable {
    let legs: [Leg]
    let overviewPolyline: Polyline

    enum CodingKeys: String, CodingKey {
        case legs
        case overviewPolyline = "overview_polyline"
    }
}

// MARK: - Leg
/// section of the route, from start to destination
struct Leg: Codable {
    let steps: [Step]
}

// MARK: - Step
/// A single navigation step with instructions, distance, and polyline
struct Step: Codable {
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

// MARK: - Distance & Duration
struct Distance: Codable {
    let text: String
    let value: Int
}

struct Duration: Codable {
    let text: String
    let value: Int
}

// MARK: - Polyline
/// Encoded polyline representing a path
struct Polyline: Codable {
    let points: String
}

// MARK: - Location
struct Location: Codable {
    let lat: Double
    let lng: Double
    
    /// Convenience computed property for CLLocationCoordinate2D.
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
