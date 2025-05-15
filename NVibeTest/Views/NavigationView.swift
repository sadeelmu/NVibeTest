//
//  NavigationView.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 13/05/2025.
//

import SwiftUI
import MapKit
import RxSwift
import RxCocoa
import Combine
import CoreLocation

struct NavigationViewUI: View {
    @ObservedObject var viewModelWrapper: NavigationViewModelWrapper
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack(spacing: 12) {
            // Departure TextField with suggestions
            VStack(alignment: .leading, spacing: 0) {
                TextField("Adresse de départ", text: $viewModelWrapper.departureAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if !viewModelWrapper.departureSuggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModelWrapper.departureSuggestions, id: \.self) { suggestion in
                                Text(suggestion)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .background(Color.white)
                                    .onTapGesture {
                                        viewModelWrapper.departureAddress = suggestion
                                        viewModelWrapper.departureSuggestions = []
                                    }
                                    .border(Color.gray.opacity(0.5), width: 0.5)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                }
            }
            
            // Arrival TextField with suggestions
            VStack(alignment: .leading, spacing: 0) {
                TextField("Adresse d'arrivée", text: $viewModelWrapper.arrivalAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if !viewModelWrapper.arrivalSuggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModelWrapper.arrivalSuggestions, id: \.self) { suggestion in
                                Text(suggestion)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .background(Color.white)
                                    .onTapGesture {
                                        viewModelWrapper.arrivalAddress = suggestion
                                        viewModelWrapper.arrivalSuggestions = []
                                    }
                                    .border(Color.gray.opacity(0.5), width: 0.5)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                }
            }
            
            Button("Calculer l'itinéraire") {
                viewModelWrapper.fetchRoute()
            }
            .padding()
            
            MapView(steps: viewModelWrapper.routeSteps, region: $region)
                .edgesIgnoringSafeArea(.bottom)
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
            
            List(viewModelWrapper.routeSteps) { step in
                VStack(alignment: .leading) {
                    Text(step.htmlInstructions.stripHTML())
                        .font(.headline)
                    Text(step.distance.text)
                        .font(.subheadline)
                }
            }
        }
        .background(Color(white: 0.95)) 
    }
}


// Wrapper to bridge RxSwift ViewModel with SwiftUI
final class NavigationViewModelWrapper: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let disposeBag = DisposeBag()
    private let viewModel: NavigationViewModel

    @Published var departureAddress: String = ""
    @Published var arrivalAddress: String = ""
    @Published var routeSteps: [RouteStep] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    @Published var departureSuggestions: [String] = []
    @Published var arrivalSuggestions: [String] = []

    var routeCoordinatesPublisher: Published<[RouteStep]>.Publisher { $routeSteps }

    private var cancellables = Set<AnyCancellable>()

    // LocalSearchCompleters for autocomplete
    private let departureSearchCompleter = MKLocalSearchCompleter()
    private let arrivalSearchCompleter = MKLocalSearchCompleter()

    override init() {
        fatalError("Use init(viewModel:) instead")
    }

    init(viewModel: NavigationViewModel) {
        self.viewModel = viewModel
        super.init()

        departureSearchCompleter.delegate = self
        arrivalSearchCompleter.delegate = self

        departureSearchCompleter.resultTypes = .address
        arrivalSearchCompleter.resultTypes = .address

        // Sync SwiftUI inputs -> RxSwift BehaviorRelay
        $departureAddress
            .sink { [weak self] newValue in
                self?.viewModel.departureAddress.accept(newValue)
                self?.departureSearchCompleter.queryFragment = newValue
            }
            .store(in: &cancellables)

        $arrivalAddress
            .sink { [weak self] newValue in
                self?.viewModel.arrivalAddress.accept(newValue)
                self?.arrivalSearchCompleter.queryFragment = newValue
            }
            .store(in: &cancellables)

        // Bind RxSwift outputs -> SwiftUI Published
        viewModel.routeSteps
            .drive(onNext: { [weak self] steps in
                self?.routeSteps = steps
            })
            .disposed(by: disposeBag)

        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                self?.isLoading = loading
            })
            .disposed(by: disposeBag)

        viewModel.errorMessage
            .drive(onNext: { [weak self] message in
                self?.errorMessage = message
            })
            .disposed(by: disposeBag)
    }

    func fetchRoute() {
        viewModel.fetchRouteTrigger.accept(())
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let addresses = completer.results.map { $0.title + ", " + $0.subtitle }

            if completer == self.departureSearchCompleter {
                self.departureSuggestions = addresses
            } else if completer == self.arrivalSearchCompleter {
                self.arrivalSuggestions = addresses
            }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle error if needed
        print("Autocomplete error: \(error.localizedDescription)")
    }
}
