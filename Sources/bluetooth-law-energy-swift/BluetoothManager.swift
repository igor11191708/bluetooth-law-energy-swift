//
//  BluetoothLEManager.swift
//
//
//  Created by Igor  on 12.07.24.
//

import Combine
import CoreBluetooth

/// A manager class for handling Bluetooth Low Energy (BLE) operations, implementing ObservableObject.
@MainActor
@available(macOS 11, iOS 14, tvOS 15.0, watchOS 8.0, *)
public class BluetoothLEManager: NSObject, ObservableObject {
    
    /// A typealias for the state publisher.
    public typealias StatePublisher = AnyPublisher<CBManagerState, Never>
    
    /// A typealias for the peripheral publisher.
    public typealias PeripheralPublisher = AnyPublisher<[CBPeripheral], Never>
    
    /// A published property to indicate if Bluetooth is authorized.
    @Published public var isAuthorized = false
    
    /// A published property to indicate if Bluetooth is powered on.
    @Published public var isPowered = false

    /// A published property to indicate if scanning for peripherals is ongoing.
    @Published public var isScanning = false
    
    /// A computed property to get the state publisher from the delegate handler.
    public var getStatePublisher: StatePublisher { delegateHandler.statePublisher }
    
    /// A computed property to get the peripheral publisher from the delegate handler.
    public var getPeripheralPublisher: PeripheralPublisher { delegateHandler.peripheralPublisher }
    
    // MARK: - Private properties
    
    /// Limit time for discovering services
    private var timeout : UInt64 = 10
    
    /// A typealias for the delegate handler.
    private typealias Delegate = BluetoothDelegate
    
    /// An instance of the State struct for Bluetooth state checks.
    private let state = BluetoothLEManager.State()
    
    /// An instance of the Stream class to manage peripheral streams.
    private let stream = Stream()
    
    /// The central manager for managing BLE operations.
    private let centralManager: CBCentralManager
    
    /// The delegate handler for handling central manager delegate methods.
    private let delegateHandler: Delegate
    
    /// A set of AnyCancellable to hold Combine subscriptions.
    private var cancellables: Set<AnyCancellable> = []
    
    /// Semaphore to control access to the discoverServices method
    private let discoverServicesSemaphore = DispatchSemaphore(value: 1)
    
    // MARK: - Life cycle
    
    /// Initializes a new instance of the BluetoothLEManager.
    public override init() {
        delegateHandler = Delegate()
        centralManager = CBCentralManager(delegate: delegateHandler, queue: nil)
        super.init()
        setupSubscriptions()
        print("BluetoothManager initialized on \(Date())")
    }
    
    /// Deinit the BluetoothLEManager.
    deinit {
        print("BluetoothManager deinitialized")
    }
    
    // MARK: - Public API
    
    /// Provides an asynchronous stream of discovered Bluetooth peripherals.
    ///
    /// - Returns: An `AsyncStream` of an array of `CBPeripheral` objects.
    public var peripheralsStream: AsyncStream<[CBPeripheral]> {
        return stream.peripheralsStream()
    }
    
    /// Discovers services for a given peripheral.
    ///
    /// - Parameter peripheral: The `CBPeripheral` instance for which to discover services.
    /// - Returns: An array of `CBService` representing the services supported by the peripheral.
    /// - Throws: A `BluetoothLEManager.Errors` error if service discovery fails or the peripheral is already connected.
    nonisolated public func discoverServices(for peripheral: CBPeripheral) async throws -> [CBService] {
        // Wait for the semaphore to ensure only one discovery process runs at a time
        discoverServicesSemaphore.wait()
        defer {
            // Signal the semaphore to allow the next method execution
            discoverServicesSemaphore.signal()
        }

        // TODO: add timeout for the whole discovering interval
        
        try PeripheralDelegate.checkIfConnected(for: peripheral)

        // Step 1: Connect to the peripheral
        try await delegateHandler.connect(to: peripheral, with: centralManager)
        
        // Step 2: Discover services on the peripheral
        let services = try await PeripheralDelegate.discoverServices(for: peripheral)

        // Step 3: Disconnect from the peripheral
        try await delegateHandler.disconnect(from: peripheral, with: centralManager)

        return services
    }

    // MARK: - Private Methods

    
    /// Sets up Combine subscriptions for state and peripheral updates.
    private func setupSubscriptions() {
        
        getPeripheralPublisher
            .sink { [weak self] peripherals in
                self?.handlePeripheralChange(peripherals)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(getStatePublisher, stream.subscriberCountPublisher)
            .sink { [weak self] state, subscriberCount in
                self?.checkForScan(state, subscriberCount)
            }
            .store(in: &cancellables)
    }
    
    /// Handles changes to the discovered peripherals.
    ///
    /// - Parameter peripherals: An array of discovered `CBPeripheral` objects.
    private func handlePeripheralChange(_ peripherals: [CBPeripheral]) {
        stream.updatePeripherals(peripherals)
    }
    
    /// A computed property to check if Bluetooth is ready (authorized and powered on).
    private var checkIfBluetoothReady: Bool {
        
        isAuthorized = State.isBluetoothAuthorized
        
        isPowered = State.isBluetoothPoweredOn(for: centralManager)
        
        return isPowered && isAuthorized
    }
    
    /// Checks the state and subscriber count to determine if scanning should start or stop.
    ///
    /// - Parameters:
    ///   - state: The current state of the central manager.
    ///   - subscriberCount: The current number of subscribers.
    private func checkForScan(_ state: CBManagerState, _ subscriberCount: Int) {

        guard checkIfBluetoothReady else {
            stopScanning()
            return
        }
        
        if subscriberCount == 0 {
            stopScanning()
        } else if subscriberCount > 0 {
            startScanning()
        }
    }
    
    /// Starts scanning for Bluetooth peripherals.
    private func startScanning() {
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /// Stops scanning for Bluetooth peripherals.
    private func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }
}
