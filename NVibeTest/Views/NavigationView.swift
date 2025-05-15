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
        ScrollView {
            VStack(spacing: 16) {
                
                // MARK: Departure Input & Suggestions
                VStack(alignment: .leading, spacing: 0) {
                    TextField("Adresse de départ", text: $viewModelWrapper.departureAddress)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if !viewModelWrapper.departureSuggestions.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModelWrapper.departureSuggestions, id: \.self) { suggestion in
                                    Text(suggestion)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .onTapGesture {
                                            viewModelWrapper.departureAddress = suggestion
                                            viewModelWrapper.departureSuggestions = []
                                        }
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .frame(maxHeight: 88) // fixed max height, scrollable
                    }
                }
                
                // MARK: Arrival Input & Suggestions
                VStack(alignment: .leading, spacing: 0) {
                    TextField("Adresse d'arrivée", text: $viewModelWrapper.arrivalAddress)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if !viewModelWrapper.arrivalSuggestions.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModelWrapper.arrivalSuggestions, id: \.self) { suggestion in
                                    Text(suggestion)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .onTapGesture {
                                            viewModelWrapper.arrivalAddress = suggestion
                                            viewModelWrapper.arrivalSuggestions = []
                                        }
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .frame(maxHeight: 88) // fixed max height, scrollable
                    }
                }
                
                // MARK: Calculate Button
                Button(action: {
                    viewModelWrapper.fetchRoute()
                }) {
                    Text("Calculer l'itinéraire")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // MARK: MapView
                MapView(
                    overviewPolyline: viewModelWrapper.overviewPolyline,
                    steps: viewModelWrapper.routeSteps,
                    region: $region
                )
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)

                
                // MARK: Route Steps
                if !viewModelWrapper.routeSteps.isEmpty {
                    Text("Étapes de l'itinéraire")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(viewModelWrapper.routeSteps) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.htmlInstructions.stripHTML())
                                    .font(.body)
                                Text(step.distance.text)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .background(Color(white: 0.95).ignoresSafeArea())
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
    @Published var overviewPolyline: MKPolyline? = nil

    @Published var departureSuggestions: [String] = []
    @Published var arrivalSuggestions: [String] = []

    private var cancellables = Set<AnyCancellable>()

    private let departureSearchCompleter = MKLocalSearchCompleter()
    private let arrivalSearchCompleter = MKLocalSearchCompleter()

    init(viewModel: NavigationViewModel) {
        self.viewModel = viewModel
        super.init()

        departureSearchCompleter.delegate = self
        arrivalSearchCompleter.delegate = self

        departureSearchCompleter.resultTypes = .address
        arrivalSearchCompleter.resultTypes = .address

        // Bind the overviewPolyline from the underlying viewModel to our @Published var
        viewModel.overviewPolyline
            .drive(onNext: { [weak self] polyline in
                self?.overviewPolyline = polyline
            })
            .disposed(by: disposeBag)

        // Bind the routeSteps from viewModel to our @Published
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

        // Debounced Departure Input
        $departureAddress
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.viewModel.departureAddress.accept(query)
                self?.departureSearchCompleter.queryFragment = query
            }
            .store(in: &cancellables)

        // Debounced Arrival Input
        $arrivalAddress
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.viewModel.arrivalAddress.accept(query)
                self?.arrivalSearchCompleter.queryFragment = query
            }
            .store(in: &cancellables)
    }

    func fetchRoute() {
        viewModel.fetchRouteTrigger.accept(())
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let suggestions = completer.results.map { "\($0.title), \($0.subtitle)" }
            if completer == self.departureSearchCompleter {
                self.departureSuggestions = suggestions
            } else if completer == self.arrivalSearchCompleter {
                self.arrivalSuggestions = suggestions
            }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("SearchCompleter failed: \(error.localizedDescription)")
    }
}

