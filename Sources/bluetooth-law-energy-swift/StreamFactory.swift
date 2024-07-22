//
//  StreamFactory.swift
//
//  Manages the creation and handling of streams for Bluetooth peripheral data.
//
//  Created by Igor on 12.07.24.
//

import Combine
import CoreBluetooth

extension BluetoothLEManager {
    
    /// `StreamFactory` is responsible for creating and managing streams related to Bluetooth peripherals.
    final class StreamFactory {
        
        /// Publisher to expose the number of subscribers.
        public var subscriberCountPublisher: AnyPublisher<Int, Never> {
            subscriberCountSubject
                .eraseToAnyPublisher()
        }
        
        /// Subject to manage subscriber counts internally.
        private let subscriberCountSubject = PassthroughSubject<Int, Never>()
        
        /// Internal service for handling registration and notification of subscribers.
        private let service: RegistrationStream
        
        /// Set to hold any Combine cancellables to manage memory and avoid leaks.
        private var cancellables = Set<AnyCancellable>()
        
        // MARK: - Initializer
        
        /// Initializes the StreamFactory and subscribes to the service's subscriber count.
        init() {
            self.service = RegistrationStream()
            Task {
                await self.service.subscriberCountPublisher
                    .sink { [weak self] count in
                        guard let self = self else { return }
                        self.subscriberCountSubject.send(count)
                    }
                    .store(in: &self.cancellables)
            }
        }
        
        /// Prints debug message on deinitialization to help with tracking lifecycle issues.
        deinit {
            #if DEBUG
            print("Stream deinitialized")
            #endif
        }
        
        // MARK: - API
        
        /// Provides an asynchronous stream of discovered peripherals.
        public func peripheralsStream() async -> AsyncStream<[CBPeripheral]> {
            await service.stream
        }
        
        /// Updates the list of peripherals and notifies all subscribers.
        public func updatePeripherals(_ peripherals: [CBPeripheral]) async {
           await self.service.notifySubscribers(peripherals)
        }
    }
}
