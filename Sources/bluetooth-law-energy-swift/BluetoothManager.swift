import SwiftUI
import Combine
import CoreBluetooth

@MainActor
public class BluetoothManager: NSObject, ObservableObject {
    
    @Published public var showPowerAlert = false
    @Published public var showAuthorizeAlert = false
    @Published public var isAuthorized = false
    @Published public var isPowered = false
    
    private let state = State()
    private let stream = Stream()
    private let centralManager: CBCentralManager
    private let delegateHandler: BluetoothDelegateHandler
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Life cycle
    
    public override init() {
        delegateHandler = BluetoothDelegateHandler()
        centralManager = CBCentralManager(delegate: delegateHandler, queue: nil)
        super.init()
        setupSubscriptions()
        print("BluetoothManager initialized on \(Date())")
    }
    
    deinit {
        print("BluetoothManager deinitialized")
    }
    
    // MARK: - Public API
    
    public func peripheralsStream() -> AsyncStream<[CBPeripheral]> {
        return stream.peripheralsStream()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        let statePublisher = delegateHandler.stateSubject
            .dropFirstIfPoweredOff()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        let peripheralPublisher = delegateHandler.peripheralSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        let stateActionPublisher = state.actionSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        let subscriberCountPublisher = stream.subscriberCountSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        statePublisher
            .sink { [weak self] state in
                print(state.rawValue, "test")
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        peripheralPublisher
            .sink { [weak self] peripherals in
                self?.handlePeripheralChange(peripherals)
            }
            .store(in: &cancellables)
        
        stateActionPublisher
            .sink { [weak self] action in
                self?.handleStateAction(action)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(statePublisher, subscriberCountPublisher)
            .sink { [weak self] state, subscriberCount in
                self?.handleStateAndSubscriberCount(subscriberCount: subscriberCount)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: CBManagerState) {
        self.state.updateState(state)
    }
    
    private func handlePeripheralChange(_ peripherals: [CBPeripheral]) {
        stream.updatePeripherals(peripherals)
    }
    
    private func handleStateAction(_ action: State.Action) {
        switch action {
        case .power:
            showPowerAlert = true
        case .requestPermission:
            startScanning() // This triggers the authorization prompt
        case .authorize:
            self.showAuthorizeAlert = true
        }
    }
    
    private func handleStateAndSubscriberCount(subscriberCount: Int) {
        self.isAuthorized = State.isBluetoothAuthorized
        self.isPowered = State.isBluetoothPoweredOn(for: centralManager)
        let isBluetoothReady = isPowered && isAuthorized
        
        if subscriberCount == 0 {
            stopScanning()
        } else if subscriberCount > 0 && isBluetoothReady {
            startScanning()
        }
    }
    
    private func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    private func stopScanning() {
        centralManager.stopScan()
    }
    
    // MARK: - Nested Classes
    
    private class Stream {
        
        public let subscriberCountSubject = PassthroughSubject<Int, Never>()
        
        private typealias PeripheralsContinuation = AsyncStream<[CBPeripheral]>.Continuation
        
        private var discoveredPeripherals: [CBPeripheral] = []
        
        private var subscribers: [UUID: PeripheralsContinuation] = [:]
        
        private let queue = DispatchQueue(label: "BluetoothManagerQueue", attributes: .concurrent)
        
        private var getID : UUID { .init() }
        
        // MARK: - API
        
        public func peripheralsStream() -> AsyncStream<[CBPeripheral]> {
            return AsyncStream { continuation in
                queue.async(flags: .barrier) {
                    let subscriberID = self.getID
                    self.initializeSubscriber(with: subscriberID, and: continuation)
                    self.onTerminateSubscriber(with: subscriberID, and: continuation)
                }
            }
        }
        
        public func updatePeripherals(_ peripherals: [CBPeripheral]) {
            discoveredPeripherals = peripherals
            notifySubscribers()
        }
        
        // MARK: - Private methods
        
        private func initializeSubscriber(with id: UUID, and continuation: PeripheralsContinuation) {
            subscribers[id] = continuation
            continuation.yield(discoveredPeripherals)
            subscriberCountSubject.send(subscribers.count)
        }
        
        private func onTerminateSubscriber(with id: UUID, and continuation: PeripheralsContinuation) {
            continuation.onTermination = { [weak self] _ in
                self?.queue.async(flags: .barrier) {
                    self?.subscribers.removeValue(forKey: id)
                    self?.subscriberCountSubject.send(self?.subscribers.count ?? 0)
                }
            }
        }
        
        private func notifySubscribers() {
            let currentPeripherals = discoveredPeripherals
            for continuation in subscribers.values {
                continuation.yield(currentPeripherals)
            }
        }
    }
    
    private class State {
        let actionSubject = PassthroughSubject<BluetoothManager.State.Action, Never>()
        
        public enum Action {
            case power
            case requestPermission
            case authorize
        }
        
        static var isBluetoothAuthorized: Bool {
            return CBCentralManager.authorization == .allowedAlways
        }
        
        static func isBluetoothPoweredOn(for centralManager: CBCentralManager) -> Bool {
            return centralManager.state == .poweredOn
        }
        
        func updateState(_ state: CBManagerState) {
            switch state {
            case .poweredOn:
                checkBluetoothAuthorization()
            case .poweredOff:
                actionSubject.send(.power)
            case .unauthorized:
                checkBluetoothAuthorization()
            default:
                break
            }
        }
        
        private func checkBluetoothAuthorization() {
            switch CBCentralManager.authorization {
            case .allowedAlways:
                break
            case .restricted, .denied:
                actionSubject.send(.authorize)
            case .notDetermined:
                actionSubject.send(.requestPermission)
            @unknown default:
                break
            }
        }
    }
}

public class BluetoothDelegateHandler: NSObject, CBCentralManagerDelegate {
    let stateSubject = PassthroughSubject<CBManagerState, Never>()
    let peripheralSubject = CurrentValueSubject<[CBPeripheral], Never>([])
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateSubject.send(central.state) // Send state updates through the subject
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var peripherals = peripheralSubject.value
        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral)
            peripheralSubject.send(peripherals)
        }
    }
}

extension Publisher where Output == CBManagerState, Failure == Never {
    func dropFirstIfPoweredOff() -> AnyPublisher<CBManagerState, Never> {
        self.scan((0, CBManagerState.unknown)) { acc, newState in
            let (count, _) = acc
            return (count + 1, newState)
        }
        .drop { (count, state) in
            return count == 1 && state == .poweredOff
        }
        .map { $0.1 } // Extract the actual CBManagerState value from the tuple
        .eraseToAnyPublisher()
    }
}
