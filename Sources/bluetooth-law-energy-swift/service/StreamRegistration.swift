//
//  RegistrationStream.swift
//
//  Manages Bluetooth low energy peripheral discovery stream.
//
//  Created by Igor on 22.07.24.
//

import Combine
import CoreBluetooth

extension BluetoothLEManager {
    
    /// An actor to handle the registration and streaming of discovered Bluetooth peripherals.
    actor StreamRegistration {
        
        /// Dictionary to keep track of subscribers using UUIDs.
        private var subscribers: [UUID: PeripheralsContinuation] = [:]
        
        /// Subject to broadcast changes in subscriber count.
        private let subscriberCountSubject = PassthroughSubject<Int, Never>()
        
        /// List to store discovered peripherals.
        private var discoveredPeripherals: [CBPeripheral] = []
        
        
        /// Defines a continuation type specific to an array of CBPeripheral.
        public typealias PeripheralsContinuation = AsyncStream<[CBPeripheral]>.Continuation
        
        /// Publisher to provide subscriber count changes externally.
        public var subscriberCountPublisher: AnyPublisher<Int, Never> {
            subscriberCountSubject.eraseToAnyPublisher()
        }
        
        /// Computed property to get the number of current subscribers.
        public var count: Int {
            return subscribers.count
        }
        
        /// Provides an asynchronous stream of peripheral arrays.
        public var stream: AsyncStream<[CBPeripheral]> {
            get {
                createPeripheralStream()
            }
        }
        
        /// Registers a new subscriber and immediately provides current peripherals.
        ///
        /// - Parameters:
        ///   - id: The UUID of the subscriber to register.
        ///   - continuation: The `PeripheralsContinuation` to handle the discovered peripherals.
        public func register(with id: UUID, and continuation: PeripheralsContinuation) {
            subscribers[id] = continuation
            continuation.yield(discoveredPeripherals)
            subscriberCountSubject.send(count)
        }
        
        /// Unregisters a subscriber, reducing the subscriber count.
        ///
        /// - Parameter id: The UUID of the subscriber to unregister.
        public func unregister(with id: UUID) {
            subscribers.removeValue(forKey: id)
            subscriberCountSubject.send(count)
        }
        
        /// Notifies all subscribers with the latest list of discovered peripherals.
        ///
        /// - Parameter peripherals: The updated list of discovered `CBPeripheral` instances.
        public func notifySubscribers(_ peripherals: [CBPeripheral]) {
            discoveredPeripherals = peripherals
            for continuation in subscribers.values {
                continuation.yield(peripherals)
            }
        }
        
        /// Creates and returns an `AsyncStream` of peripherals, handling lifecycle events.
        ///
        /// - Returns: An `AsyncStream` of `[CBPeripheral]` to provide the peripheral data.
        private func createPeripheralStream() -> AsyncStream<[CBPeripheral]> {
            AsyncStream<[CBPeripheral]> { [weak self] continuation in
                guard let self = self else { return }
                Task {
                    let id = UUID()
                    await self.register(with: id, and: continuation)
                    continuation.onTermination = { [weak self] _ in
                        guard let self = self else { return }
                        Task {
                            await self.unregister(with: id)
                        }
                    }
                }
            }
        }
    }
}
