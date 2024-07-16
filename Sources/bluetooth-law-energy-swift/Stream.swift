//
//  Stream.swift
//
//
//  Created by Igor  on 12.07.24.
//

import Combine
import CoreBluetooth

extension BluetoothLEManager{

    /// A  class that manages a stream of discovered Bluetooth peripherals and the subscriber count.
    final class Stream {
        
        /// A publisher that emits the current number of subscribers.
        public var subscriberCountPublisher: AnyPublisher<Int, Never> {
            subscriberCountSubject
                .receiveOnMainAndEraseToAnyPublisher()
        }
        
        /// A subject to publish the current number of subscribers.
        private let subscriberCountSubject = PassthroughSubject<Int, Never>()
        
        /// Typealias for the continuation used in AsyncStream for peripherals.
        private typealias PeripheralsContinuation = AsyncStream<[CBPeripheral]>.Continuation
        
        /// An array to hold discovered Bluetooth peripherals.
        private var discoveredPeripherals: [CBPeripheral] = []
        
        /// A dictionary to hold subscribers with their UUIDs and continuations.
        private var subscribers: [UUID: PeripheralsContinuation] = [:]
        
        /// A concurrent dispatch queue for managing subscriber access.
        private let queue = DispatchQueue(label: "BluetoothManager-Stream-Queue")
        
        /// Generates a new UUID.
        private var getID: UUID { .init() }
        
        // MARK: - API
        
        /// Provides an asynchronous stream of discovered Bluetooth peripherals.
        ///
        /// - Returns: An `AsyncStream` of an array of `CBPeripheral` objects.
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
        
        /// Updates the list of discovered Bluetooth peripherals and notifies all subscribers.
        ///
        /// - Parameter peripherals: An array of `CBPeripheral` objects.
        public func updatePeripherals(_ peripherals: [CBPeripheral]) {
            discoveredPeripherals = peripherals
            notifySubscribers()
        }
        
        // MARK: - Private methods
        
        /// Initializes a new subscriber with a given ID and continuation.
        ///
        /// - Parameters:
        ///   - id: The UUID of the new subscriber.
        ///   - continuation: The continuation for the `AsyncStream`.
        private func initializeSubscriber(with id: UUID, and continuation: PeripheralsContinuation) {
            subscribers[id] = continuation
            continuation.yield(discoveredPeripherals)
            subscriberCountSubject.send(subscribers.count)
        }
        
        /// Sets up the termination handler for a subscriber with a given ID and continuation.
        ///
        /// - Parameters:
        ///   - id: The UUID of the subscriber.
        ///   - continuation: The continuation for the `AsyncStream`.
        private func onTerminateSubscriber(with id: UUID, and continuation: PeripheralsContinuation) {
            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.queue.async(flags: .barrier) {
                    self.subscribers.removeValue(forKey: id)
                    self.subscriberCountSubject.send(self.subscribers.count)
                }
            }
        }
        
        /// Notifies all subscribers with the current list of discovered Bluetooth peripherals.
        private func notifySubscribers() {
            let currentPeripherals = discoveredPeripherals
            for continuation in subscribers.values {
                continuation.yield(currentPeripherals)
            }
        }
    }
}
