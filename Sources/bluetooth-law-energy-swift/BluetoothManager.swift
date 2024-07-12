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
        
        let subscriberCountPublisher = stream.subscriberCountSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        peripheralPublisher
            .sink { [weak self] peripherals in
                self?.handlePeripheralChange(peripherals)
            }
            .store(in: &cancellables)
        
        
        Publishers.CombineLatest(statePublisher, subscriberCountPublisher)
            .sink { [weak self] state, subscriberCount in
                self?.checkForScan(state, subscriberCount)
            }
            .store(in: &cancellables)
    }
    
    
    private func handlePeripheralChange(_ peripherals: [CBPeripheral]) {
        stream.updatePeripherals(peripherals)
    }
    
    private var checkIfBluetoothReady : Bool{
        
        isAuthorized = State.isBluetoothAuthorized
        showAuthorizeAlert = !isAuthorized
        
        
        isPowered = State.isBluetoothPoweredOn(for: centralManager)
        showPowerAlert = isAuthorized && !isPowered
        
        return isPowered && isAuthorized
    }
    
    private func checkForScan(_ state: CBManagerState,_ subscriberCount: Int) {

        guard checkIfBluetoothReady else{
            stopScanning()
            return
        }
        
        if subscriberCount == 0 {
            stopScanning()
        } else if subscriberCount > 0 {
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

        static var isBluetoothAuthorized: Bool {
            return CBCentralManager.authorization == .allowedAlways
        }
        
        static func isBluetoothPoweredOn(for manager: CBCentralManager) -> Bool {
            return manager.state == .poweredOn
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
