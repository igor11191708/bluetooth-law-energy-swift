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
        self.delegateHandler = BluetoothDelegateHandler()
        self.centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        self.centralManager.delegate = delegateHandler
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
            case .powerOn:
                showPowerAlert = true
            case .requestPermission:
                startScanning() // This triggers the authorization prompt
            case .authorizeInSettings:
                self.showAuthorizeAlert = true
        }
    }
    
    private func handleStateAndSubscriberCount(subscriberCount: Int) {
       
        self.isAuthorized = CBCentralManager.authorization == .allowedAlways
        self.isPowered = centralManager.state == .poweredOn
        let isBluetoothReady = isPowered && isAuthorized
        
        
        if isPowered{ showPowerAlert = false }
        
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
    
    private class Stream: ObservableObject {
        private var discoveredPeripherals: [CBPeripheral] = []
        private var subscribers: [UUID: AsyncStream<[CBPeripheral]>.Continuation] = [:]
        private let queue = DispatchQueue(label: "BluetoothManagerQueue", attributes: .concurrent)
        let subscriberCountSubject = PassthroughSubject<Int, Never>()
        
        public func peripheralsStream() -> AsyncStream<[CBPeripheral]> {
            return AsyncStream { continuation in
                queue.async(flags: .barrier) {
                    let subscriberID = UUID()
                    self.subscribers[subscriberID] = continuation
                    self.subscriberCountSubject.send(self.subscribers.count)
                    continuation.onTermination = { [weak self] _ in
                        self?.queue.async(flags: .barrier) {
                      
                            self?.subscribers.removeValue(forKey: subscriberID)
                            self?.subscriberCountSubject.send(self?.subscribers.count ?? 0)
                        }
                    }
                }
            }
        }
        
        func updatePeripherals(_ peripherals: [CBPeripheral]) {
                self.discoveredPeripherals = peripherals
                self.updateSubscribers()
        }
        
        private func updateSubscribers() {
            let currentPeripherals = discoveredPeripherals
            for continuation in subscribers.values {
                continuation.yield(currentPeripherals)
            }
        }
    }
    
    private class State: ObservableObject {
        let actionSubject = PassthroughSubject<BluetoothManager.State.Action, Never>()
        
        public enum Action {
            case powerOn
            case requestPermission
            case authorizeInSettings
        }
        
        func updateState(_ state: CBManagerState) {
            switch state {
            case .poweredOn:
                checkBluetoothAuthorization()
            case .poweredOff:
                actionSubject.send(.powerOn)
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
                actionSubject.send(.authorizeInSettings)
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
