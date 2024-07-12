import SwiftUI
import Combine
import CoreBluetooth

@MainActor
public class BluetoothManager: NSObject, ObservableObject {
    
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
            .receiveOnMainAndEraseToAnyPublisher()
        
        let peripheralPublisher = delegateHandler.peripheralSubject
            .receiveOnMainAndEraseToAnyPublisher()
        
        let subscriberCountPublisher = stream.subscriberCountSubject
            .receiveOnMainAndEraseToAnyPublisher()
        
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
        
        isPowered = State.isBluetoothPoweredOn(for: centralManager)
        
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
        
        private let queue = DispatchQueue(label: "BluetoothManagerStreamQueue", attributes: .concurrent)
        
        private var getID : UUID { .init() }
        
        // MARK: - API
        
        public func peripheralsStream() -> AsyncStream<[CBPeripheral]> {
            return AsyncStream { [weak self] continuation in
                self?.queue.async(flags: .barrier) {
                    guard let self = self else { return }
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
                guard let self = self else { return }
                self.queue.async(flags: .barrier) {
                    self.subscribers.removeValue(forKey: id)
                    self.subscriberCountSubject.send(self.subscribers.count)
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
