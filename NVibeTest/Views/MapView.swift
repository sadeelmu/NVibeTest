//
//  MapView.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import SwiftUI
import MapKit
import UIKit

struct MapView: UIViewRepresentable {
    var steps: [RouteStep]  // Use route steps for multi-segment drawing
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        
        // Remove all overlays & annotations
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // Colors to cycle through for steps
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed, .systemTeal]

        for (index, step) in steps.enumerated() {
            let coords = PolylineDecoder.decodePolyline(step.polyline.points)
            guard !coords.isEmpty else { continue }

            let polyline = ColorPolyline(coordinates: coords, count: coords.count)
            polyline.color = colors[index % colors.count]
            uiView.addOverlay(polyline)
            
            // Add pin annotation for step instructions
            let annotation = MKPointAnnotation()
            annotation.coordinate = coords.first!
            annotation.title = step.htmlInstructions.stripHTML()
            uiView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Custom polyline subclass to hold color
    class ColorPolyline: MKPolyline {
        var color: UIColor = .systemBlue
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        init(_ parent: MapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? ColorPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = polyline.color
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "stepPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            return view
        }
    }
}
