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
            
            // Pass routeSteps, not just coordinates
            MapView(steps: viewModelWrapper.routeSteps, region: $region)
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
        .onReceive(viewModelWrapper.$routeSteps) { steps in
            // Zoom map to fit all step coordinates
            let allCoords = steps.flatMap { PolylineDecoder.decodePolyline($0.polyline.points) }
            guard !allCoords.isEmpty else { return }
            
            let mapRect = allCoords.reduce(MKMapRect.null) { partialResult, coord in
                let point = MKMapPoint(coord)
                let rect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
                return partialResult.union(rect)
            }
            
            // Animate region update on main thread
            DispatchQueue.main.async {
                region = MKCoordinateRegion(mapRect)
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
    
    var routeCoordinatesPublisher: Published<[RouteStep]>.Publisher { $routeSteps }
    
    private var cancellables = Set<AnyCancellable>()
    
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
    }
    
    func fetchRoute() {
        viewModel.fetchRouteTrigger.accept(())
    }
}
