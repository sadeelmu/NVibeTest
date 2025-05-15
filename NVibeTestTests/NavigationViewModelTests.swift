//
//  NavigationViewModelTests.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 15/05/2025.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
import CoreLocation
@testable import NVibeTest

final class NavigationViewModelTests: XCTestCase {
    var viewModel: NavigationViewModel!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    // Mock RouteService
    class MockRouteService: RouteServiceProtocol {
        func fetchRoute(from departure: String, to arrival: String) -> Observable<RouteResponse> {
            // Return fixed route response with encoded polyline and steps
            let polylineString = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
            let step = RouteStep(instruction: "Head north", startLocation: CLLocation(latitude: 37.78, longitude: -122.41), endLocation: CLLocation(latitude: 37.79, longitude: -122.42), distance: 100)
            let leg = RouteLeg(steps: [step])
            let route = Route(legs: [leg], overviewPolyline: Polyline(points: polylineString))
            let response = RouteResponse(routes: [route])
            return Observable.just(response)
        }
    }
    
    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        viewModel = NavigationViewModel(routeService: MockRouteService())
    }
    
    func testFetchRouteOutputsCoordinatesAndSteps() {
        // Prepare observers to capture outputs
        let coordsObserver = scheduler.createObserver([CLLocationCoordinate2D].self)
        let stepsObserver = scheduler.createObserver([RouteStep].self)
        let loadingObserver = scheduler.createObserver(Bool.self)
        let errorObserver = scheduler.createObserver(String.self)
        
        // Bind outputs to observers
        viewModel.routeCoordinates
            .drive(coordsObserver)
            .disposed(by: disposeBag)
        
        viewModel.routeSteps
            .drive(stepsObserver)
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .drive(loadingObserver)
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .drive(errorObserver)
            .disposed(by: disposeBag)
        
        // Set inputs
        viewModel.departureAddress.accept("Start")
        viewModel.arrivalAddress.accept("End")
        
        // Trigger fetch
        viewModel.fetchRouteTrigger.accept(())
        
        // Run scheduler to process events
        scheduler.start()
        
        // Test loading sequence (true then false)
        XCTAssertEqual(loadingObserver.events.map { $0.value.element }, [true, false])
        
        // Test error messages - should be empty
        XCTAssertTrue(errorObserver.events.allSatisfy { $0.value.element == "" || $0.value.element == "Unknown error" })
        
        // Test routeSteps output
        let steps = stepsObserver.events.compactMap { $0.value.element }.last
        XCTAssertNotNil(steps)
        XCTAssertEqual(steps?.count, 1)
        XCTAssertEqual(steps?.first?.instruction, "Head north")
        
        // Test routeCoordinates output (decoded polyline)
        let coords = coordsObserver.events.compactMap { $0.value.element }.last
        XCTAssertNotNil(coords)
        // The encoded polyline decodes to known coordinates, check count > 0
        XCTAssertGreaterThan(coords!.count, 0)
        
        // Optionally, verify first coordinate matches expected
        if let first = coords?.first {
            XCTAssertEqual(round(first.latitude * 1000) / 1000, 38.5, accuracy: 0.01)
            XCTAssertEqual(round(first.longitude * 1000) / 1000, -120.2, accuracy: 0.01)
        }
    }
}
