//
//  BluetoothLEManager.swift
//
//
//  Created by Igor  on 12.07.24.
//

import Combine
import CoreBluetooth
import retry_policy_service

@available(macOS 12, iOS 15, tvOS 15.0, watchOS 8.0, *)
public actor BluetoothLEManager: NSObject, ObservableObject, Sendable {
       
    @MainActor
    public let bleState: CurrentValueSubject<BLEState, Never> = .init(.init())
    
    var isAuthorized = false
    var isPowered = false
    var isScanning = false

    private typealias StatePublisher = AnyPublisher<CBManagerState, Never>
    private typealias PeripheralPublisher = AnyPublisher<[CBPeripheral], Never>
    private var getStatePublisher: StatePublisher { delegateHandler.statePublisher }
    private var getPeripheralPublisher: PeripheralPublisher { delegateHandler.peripheralPublisher }
    private typealias Delegate = BluetoothDelegate
    private let state = BluetoothLEManager.State()
    private let stream = Stream()
    private let centralManager: CBCentralManager
    private let delegateHandler: Delegate
    private var cancellables: Set<AnyCancellable> = []
    public let queue = DispatchQueue(label: "BluetoothLEManager-CBCentralManager-Queue", attributes: .concurrent)
    
    private let cachedServices = CachedServices()
    
    public override init() {
        delegateHandler = Delegate()
        centralManager = CBCentralManager(delegate: delegateHandler, queue: queue)
        super.init()
        Task{
          await setupSubscriptions()
        }
        print("BluetoothManager initialized on \(Date())")
    }
    
    deinit {
        print("BluetoothManager deinitialized")
    }
    
    @MainActor
    public func connect(to peripheral: CBPeripheral) async throws {
        
        guard peripheral.isNotConnected else {
            throw Errors.connected(peripheral)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                let id = peripheral.getId
                let name = peripheral.getName
                try await delegateHandler.register(to: id, name: name, with: continuation)
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    @MainActor
    public var peripheralsStream: AsyncStream<[CBPeripheral]> {
        return stream.peripheralsStream()
    }
    
    @MainActor
    public func fetchServices(for peripheral: CBPeripheral, cache : Bool = true) async throws -> [CBService] {
        defer {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        let retry = RetryService(strategy: .exponential(retry: 5, multiplier: 2, duration: .seconds(5), timeout: .seconds(150)))

        for (step, delay) in retry.enumerated(){
            do{
                try await connect(to: peripheral)
                return try await discover(for: peripheral, cache: cache)
            }catch{
                if cache, let services = await cachedServices.getData(key: peripheral.getId){
                    return services
                }
            }
            try? await Task.sleep(nanoseconds: delay)
        }
            
        try await connect(to: peripheral)
        return try await discover(for: peripheral, cache: cache)

    }
    
    @MainActor
    private func discover(for peripheral: CBPeripheral, cache : Bool) async throws -> [CBService] {
        
        defer{ peripheral.delegate = nil }
        
        let delegate = PeripheralDelegate()
            peripheral.delegate = delegate
        let services = try await delegate.fetchServices(for: peripheral)
        if cache{
            await cachedServices.add(key: peripheral.getId, services: services)
        }
        return services
    }
    
    private func setupSubscriptions() {
        getPeripheralPublisher
            .sink { [weak self] peripherals in
                guard let self = self else { return }
                Task {
                    await self.handlePeripheralChange(peripherals)
                }
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(getStatePublisher, stream.subscriberCountPublisher)
            .receiveOnMainAndEraseToAnyPublisher()
            .sink { [weak self] state, subscriberCount in
                guard let self = self else { return }
                Task(priority: .userInitiated) {
                    let state = await self.checkForScan(state, subscriberCount)
                    await MainActor.run { self.bleState.send(state) }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handlePeripheralChange(_ peripherals: [CBPeripheral]) {
        stream.updatePeripherals(peripherals)
    }
    
    private var checkIfBluetoothReady: Bool {
        isAuthorized = State.isBluetoothAuthorized
        isPowered = State.isBluetoothPoweredOn(for: centralManager)
        return isPowered && isAuthorized
    }
    
    private func checkForScan(_ state: CBManagerState, _ subscriberCount: Int) -> BLEState {
        guard checkIfBluetoothReady else {
            stopScanning()
            return .init(
                isAuthorized: self.isAuthorized,
                isPowered: self.isPowered,
                isScanning: self.isScanning
            )
        }
        
        if subscriberCount == 0 {
            stopScanning()
        } else if subscriberCount > 0 {
            startScanning()
        }
        
        isScanning = subscriberCount != 0
        return .init(
            isAuthorized: self.isAuthorized,
            isPowered: self.isPowered,
            isScanning: self.isScanning
        )
    }
    
    private func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    private func stopScanning() {
        centralManager.stopScan()
    }
}
