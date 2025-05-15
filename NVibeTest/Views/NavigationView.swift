import SwiftUI
import MapKit
import RxSwift
import RxCocoa
import Combine
import CoreLocation

struct NavigationViewUI: View {
    @ObservedObject private var viewModelWrapper: NavigationViewModelWrapper
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    init(viewModel: NavigationViewModel) {
        self.viewModelWrapper = NavigationViewModelWrapper(viewModel: viewModel)
    }
    
    var body: some View {
        VStack {
            // Input fields
            VStack(spacing: 10) {
                TextField("Departure Address", text: $viewModelWrapper.departureAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                
                TextField("Arrival Address", text: $viewModelWrapper.arrivalAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                
                Button("Get Route") {
                    viewModelWrapper.fetchRoute()
                }
                .padding()
                .disabled(viewModelWrapper.departureAddress.isEmpty || viewModelWrapper.arrivalAddress.isEmpty)
            }
            .padding()
            
            // Map with annotations for route steps
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: viewModelWrapper.routeSteps) { step in
                MapMarker(coordinate: step.startLocation.coordinate, tint: .blue)
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // Loading indicator
            if viewModelWrapper.isLoading {
                ProgressView("Loading route...")
                    .padding()
            }
            
            // Error message
            if !viewModelWrapper.errorMessage.isEmpty {
                Text(viewModelWrapper.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onReceive(viewModelWrapper.routeCoordinatesPublisher) { coords in
            if let first = coords.first {
                region = MKCoordinateRegion(
                    center: first,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
}

// Wrapper to bridge RxSwift ViewModel with SwiftUI
final class NavigationViewModelWrapper: ObservableObject {
    private let disposeBag = DisposeBag()
    private let viewModel: NavigationViewModel
    
    @Published var departureAddress: String = ""
    @Published var arrivalAddress: String = ""
    @Published var routeSteps: [RouteStep] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    var routeCoordinatesPublisher: Published<[CLLocationCoordinate2D]>.Publisher { $routeCoordinates }
    
    init(viewModel: NavigationViewModel) {
        self.viewModel = viewModel
        
        // Sync SwiftUI inputs -> RxSwift BehaviorRelay
        $departureAddress
            .sink { [weak self] newValue in
                self?.viewModel.departureAddress.accept(newValue)
            }
            .store(in: &cancellables)
        
        $arrivalAddress
            .sink { [weak self] newValue in
                self?.viewModel.arrivalAddress.accept(newValue)
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
        
        viewModel.routeCoordinates
            .drive(onNext: { [weak self] coords in
                self?.routeCoordinates = coords
            })
            .disposed(by: disposeBag)
    }
    
    func fetchRoute() {
        viewModel.fetchRouteTrigger.accept(())
    }
}
