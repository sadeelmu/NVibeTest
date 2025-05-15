//
//  NavigationViewModel.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

/// ViewModel responsible for handling navigation logic:
/// - Accepts departure and arrival addresses
/// - Fetches route data from RouteService
/// - Decodes polyline points for map display
/// - Exposes route steps for instructions
final class NavigationViewModel {
    //handles user inputs, calls RouteService, publishes route steps & loading states.

    // MARK: - Inputs
    let departureAddress = BehaviorRelay<String>(value: "")
    let arrivalAddress = BehaviorRelay<String>(value: "")
    let fetchRouteTrigger = PublishRelay<Void>()
    
    // MARK: - Outputs
    let routeCoordinates: Driver<[CLLocationCoordinate2D]>
    let routeSteps: Driver<[RouteStep]>
    let isLoading: Driver<Bool>
    let errorMessage: Driver<String>
    
    // MARK: - Private properties
    private let disposeBag = DisposeBag()
    private let routeService: RouteServiceProtocol
    
    // MARK: - Initialization
    init(routeService: RouteServiceProtocol = RouteService()) {
        self.routeService = routeService
        
    }
}
