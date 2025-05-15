//
//  PolylineDecoder.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 15/05/2025.
//

import Foundation
import CoreLocation

// MARK: - PolylineDecoder
/// Utility to decode encoded Google Maps polyline strings into CLLocationCoordinate2D array.
struct PolylineDecoder {
    /// Decodes an encoded polyline string into an array of CLLocationCoordinate2D.
    /// - Parameter encodedPolyline: The encoded polyline string.
    /// - Returns: Array of CLLocationCoordinate2D representing the path.
    static func decodePolyline(_ encodedPolyline: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedPolyline.startIndex
        let length = encodedPolyline.count

        var latitude: Int32 = 0
        var longitude: Int32 = 0

        while index < encodedPolyline.endIndex {
            var byte: UInt32 = 0
            var result: UInt32 = 0
            var shift: UInt32 = 0

            repeat {
                byte = UInt32(encodedPolyline[index].asciiValue!) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
            } while byte >= 0x20

            let deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            latitude += Int32(deltaLat)

            shift = 0
            result = 0

            repeat {
                byte = UInt32(encodedPolyline[index].asciiValue!) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
            } while byte >= 0x20

            let deltaLon = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            longitude += Int32(deltaLon)

            let lat = Double(latitude) / 1e5
            let lon = Double(longitude) / 1e5
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        return coordinates
    }
}
