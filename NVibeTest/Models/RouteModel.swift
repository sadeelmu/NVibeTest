//
//  RouteModel.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import Foundation
import CoreLocation


// MARK: - RouteModel
///model for Directions API response
struct RouteModel: Decodable {
    let routes: [Route] //list of possible routes
    let status: String //api response status
}
/// Represents a full route, containing legs and an overview polyline
struct Route: Decodable {
    let legs: [Leg]
    let overviewPolyline: Polyline

    enum CodingKeys: String, CodingKey {
        case legs
        case overviewPolyline = "overview_polyline"
    }
}

/// Represents a leg of a route containing multiple steps
struct Leg: Decodable {
    let steps: [RouteStep]
}
