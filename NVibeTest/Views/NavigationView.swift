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
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Trouver un itinéraire")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.top, 12)
            
            VStack(spacing: 0) {
                // Departure TextField + suggestions dropdown
                VStack(spacing: 0) {
                    TextField("Adresse de départ", text: $viewModelWrapper.departureAddress)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                        .padding(.horizontal, 16)
                    
                    if !viewModelWrapper.departureSuggestions.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModelWrapper.departureSuggestions, id: \.self) { suggestion in
                                    Text(suggestion)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 20)
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
                        .frame(maxHeight: 150)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .padding(.horizontal, 16)
                    }
                }
                .zIndex(2) // Make sure suggestions appear above other views
                
                // Arrival TextField + suggestions dropdown
                VStack(spacing: 0) {
                    TextField("Adresse d'arrivée", text: $viewModelWrapper.arrivalAddress)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    if !viewModelWrapper.arrivalSuggestions.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModelWrapper.arrivalSuggestions, id: \.self) { suggestion in
                                    Text(suggestion)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 20)
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
                        .frame(maxHeight: 150)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .padding(.horizontal, 16)
                    }
                }
                .zIndex(1)
            }
            
            Button(action: {
                viewModelWrapper.fetchRoute()
            }) {
                Text("Rechercher l'itinéraire")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .shadow(radius: 3)
            }
            .padding(.top, 12)
            
            MapView(steps: viewModelWrapper.routeSteps, region: $region)
                .frame(height: 200)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .shadow(radius: 3)
            
            if viewModelWrapper.routeSteps.isEmpty {
                Text("Aucune instruction pour le moment.")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            } else {
                List(viewModelWrapper.routeSteps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.htmlInstructions.stripHTML())
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(step.distance.text)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(PlainListStyle())
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Navigation")
        .navigationBarTitleDisplayMode(.inline)
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
