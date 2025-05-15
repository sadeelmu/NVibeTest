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
        
        var latitude: Int64 = 0
        var longitude: Int64 = 0
        
        while index < encodedPolyline.endIndex {
            var byte: UInt64 = 0
            var result: UInt64 = 0
            var shift: UInt64 = 0
            
            repeat {
                guard index < encodedPolyline.endIndex else { break }
                byte = UInt64(encodedPolyline[index].asciiValue!) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
            } while byte >= 0x20 && index < encodedPolyline.endIndex
            
            let deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            latitude += Int64(Int64(bitPattern: deltaLat))
            
            // reset for longitude
            shift = 0
            result = 0
            
            repeat {
                guard index < encodedPolyline.endIndex else { break }
                byte = UInt64(encodedPolyline[index].asciiValue!) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
            } while byte >= 0x20 && index < encodedPolyline.endIndex
            
            let deltaLon = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            longitude += Int64(Int64(bitPattern: deltaLon))
            
            let lat = Double(latitude) / 1e5
            let lon = Double(longitude) / 1e5
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        return coordinates
    }
}
