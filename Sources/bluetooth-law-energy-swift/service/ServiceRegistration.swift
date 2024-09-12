//
//  ServiceRegistration.swift
//
//
//  Created by Igor  on 19.07.24.
//

import CoreBluetooth

extension BluetoothLEManager {
    
    /// Actor responsible for managing service registration for Bluetooth LE operations.
    actor ServiceRegistration<T> {
        
        // MARK: - Public Properties
        
        /// The type of the service.
        public let type: ServiceType
        
        // MARK: - Private Properties
        
        /// A dictionary to keep track of registered continuations.
        private var register: [UUID: CheckedContinuation<T, Error>] = [:]
        
        /// Initializes the BluetoothLEManager.
        private let logger: ILogger
        
        // MARK: - Initializer
        
        init(type: ServiceType, logger: ILogger) {
            self.type = type
            self.logger = logger
        }
        
        deinit{
            register.forEach{ (key, value) in
                value.resume(throwing: Errors.timeout)
            }
            
            register = [:]
        }
        
        // MARK: - API
        
        /// Checks if a continuation for a given UUID is not active.
        /// - Parameter id: The UUID to check.
        /// - Returns: A Boolean value indicating whether the continuation is not active.
        public func isNotActive(_ id: UUID) -> Bool {
            return register[id] == nil
        }
        
        /// Adds a continuation for a given UUID.
        /// - Parameter continuation: The continuation to add.
        /// - Parameter id: The UUID to associate with the continuation.
        public func add(_ continuation: CheckedContinuation<T, Error>, for id: UUID) {
            register[id] = continuation
        }
        
        /// Handles the result of a peripheral operation.
        /// - Parameter peripheral: The peripheral associated with the operation.
        /// - Parameter result: The result of the operation.
        public func handleResult(for peripheral: CBPeripheral, result: Result<T, Error>) {
            let id = peripheral.identifier
            
            guard let continuation = register[id] else {
                return
            }
            
            remove(for: id)
            
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
        
        /// Registers a continuation for a given UUID and name with a timeout.
        /// - Parameters:
        ///   - id: The UUID to register.
        ///   - name: The name associated with the UUID.
        ///   - continuation: The continuation to register.
        ///   - timeout: The timeout duration for the registration.
        /// - Throws: An error if the UUID is already active.
        public func register(
            to id: UUID,
            name: String,
            with continuation: CheckedContinuation<T, Error>,
            timeout: Double = 30.0
        ) throws {
            
            guard isNotActive(id) else {
                continuation.resume(throwing: Errors.connecting(name))
                return
            }
            
            add(continuation, for: id)
            
            logger.log("\(type.rawValue) \(name)", level: .debug)
            
            timeoutTask(for: id, timeout: timeout)
        }
        
        // MARK: - Private Methods
        
        /// Removes the continuation for a given UUID.
        /// - Parameter id: The UUID to remove.
        private func remove(for id: UUID) {
            register.removeValue(forKey: id)
        }
        
        /// Schedules a timeout task for a given UUID.
        /// - Parameters:
        ///   - id: The UUID to associate with the timeout task.
        ///   - timeout: The duration before the task times out.
        private func timeoutTask(for id: UUID, timeout: Double) {
            Task {
                try? await Task.sleep(for: timeout)
                
                guard let continuation = register[id] else {
                    return
                }
                
                remove(for: id)

                logger.log("timeout \(type) \(id)", level: .debug)
                
                continuation.resume(throwing: Errors.timeout)
            }
        }
    }
}
